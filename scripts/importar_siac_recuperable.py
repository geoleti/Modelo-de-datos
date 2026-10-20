"""Actualización recuperable SIAC. Uso: py -3 importar_siac_recuperable.py"""
import csv
import hashlib
import json
import sys
from datetime import datetime
from getpass import getpass
from pathlib import Path

import psycopg
from psycopg import sql

CONFIG = Path(__file__).with_name("config_siac.local.json")
if not CONFIG.is_file():
    sys.exit("Falta config_siac.local.json. Revisar docs/ACTUALIZACION_MENSUAL.md")
cfg = json.loads(CONFIG.read_text(encoding="utf-8"))
CARPETA = Path(cfg["carpeta"])
SERVIDOR = cfg["host"]
PUERTO = int(cfg.get("puerto", 5432))
BASE = cfg.get("base", "siga")
USUARIO = cfg["usuario"]
LOTE = 50000

ARCHIVOS = [
    "Tabla Final_hasta_2019.txt",
    "Tabla Final (con encabezados).txt",
    "Tabla Final.txt",
]
COLUMNAS = [
    "Callsign", "FechaHora_Local", "Fecha_Local", "Hora_Local", "Año_Local",
    "Mes_Local", "Dia_Local", "Semana_Dia_Local", "AñoMes_Local",
    "Origen OACI", "Origen IATA", "Origen País", "Origen Provincia",
    "Destino OACI", "Destino IATA", "Destino País", "Destino Provincia",
    "City Pair", "Clasificación Vuelo", "AD_OACI", "AD_IATA", "AD_Provincia",
    "Tipo de Movimiento", "Clase de Vuelo", "Operador", "Aerolinea Nombre",
    "Aerolinea Grupo", "Aerolinea Grupo 2", "Aerolinea OACI", "Matrícula",
    "Aeronave Codigo", "Aeronave Fabricante", "Aeronave Modelo",
    "Aeronave Familia", "Aeronave Fuselaje", "Aeronave Edad", "Exclusivo Carga",
    "Aerolinea Asientos", "Asientos_Pax", "Movimientos", "Vuelos", "Carga",
    "Pax", "Pax_AD", "Pasajeros", "Pasajeros_AD", "DistanciaKM",
]


def firma(ruta):
    h = hashlib.sha256()
    with ruta.open("rb") as f:
        for bloque in iter(lambda: f.read(8 * 1024 * 1024), b""):
            h.update(bloque)
    return h.hexdigest()


def archivo_estable(ruta, stat):
    s = ruta.stat()
    if (s.st_size, s.st_mtime_ns) != (stat.st_size, stat.st_mtime_ns):
        raise RuntimeError(f"Archivo modificado durante la carga: {ruta.name}")


def incluir(fila, nombre, numero):
    try:
        anio = int(fila[4].strip())
    except ValueError as exc:
        raise ValueError(f"{nombre}: fila {numero}: Año_Local inválido") from exc
    if anio < 2015:
        return False
    if nombre == ARCHIVOS[0] and anio == 2019:
        return False
    if nombre == ARCHIVOS[1] and anio in (2023, 2024, 2025):
        return False
    return True


def preparar(conn):
    with conn.transaction():
        with conn.cursor() as cur:
            cur.execute("""CREATE TABLE IF NOT EXISTS siac.vuelos_carga
                           (LIKE siac.vuelos_raw INCLUDING DEFAULTS)""")
            # La tabla de carga no genera ID: el COPY carga archivo_id y 47 columnas.
            cur.execute("ALTER TABLE siac.vuelos_carga ALTER COLUMN id DROP NOT NULL")
            cur.execute("""CREATE INDEX IF NOT EXISTS vuelos_carga_archivo_id_idx
                           ON siac.vuelos_carga (archivo_id)""")
            cur.execute("""ALTER TABLE siac.archivos_importados
                           ADD COLUMN IF NOT EXISTS mtime_ns BIGINT""")


def obtener_trabajo(conn, nombre, st, digest):
    with conn.transaction():
        with conn.cursor() as cur:
            cur.execute("""SELECT id, hash_archivo FROM siac.archivos_importados
                           WHERE nombre_archivo=%s AND estado='completado'
                           ORDER BY id DESC LIMIT 1""", (nombre,))
            completado = cur.fetchone()
            if completado and completado[1] == digest:
                return None
            cur.execute("""SELECT id, registros_leidos, registros_importados
                           FROM siac.archivos_importados
                           WHERE nombre_archivo=%s AND hash_archivo=%s
                             AND estado='procesando'
                           ORDER BY id DESC LIMIT 1""", (nombre, digest))
            pendiente = cur.fetchone()
            if pendiente:
                return pendiente
            cur.execute("""INSERT INTO siac.archivos_importados
                           (nombre_archivo, "tamaño_bytes", hash_archivo,
                            fecha_modificacion, mtime_ns, estado)
                           VALUES (%s,%s,%s,%s,%s,'procesando') RETURNING id""",
                        (nombre, st.st_size, digest,
                         datetime.fromtimestamp(st.st_mtime), st.st_mtime_ns))
            return cur.fetchone()[0], 0, 0


def guardar_lote(conn, archivo_id, registros, leidos, importados):
    with conn.transaction():
        with conn.cursor() as cur:
            if registros:
                nombres = sql.SQL(", ").join(map(sql.Identifier, COLUMNAS))
                q = sql.SQL("COPY siac.vuelos_carga (archivo_id, {}) FROM STDIN").format(nombres)
                with cur.copy(q) as cp:
                    for fila in registros:
                        cp.write_row((archivo_id, *[x if x != "" else None for x in fila]))
            cur.execute("""UPDATE siac.archivos_importados
                           SET registros_leidos=%s, registros_importados=%s
                           WHERE id=%s AND estado='procesando'""",
                        (leidos, importados, archivo_id))


def publicar(conn, nombre, archivo_id, leidos, importados, ruta, st, digest):
    archivo_estable(ruta, st)
    if firma(ruta) != digest:
        raise RuntimeError("El contenido del archivo cambió durante la importación")
    # Publicación atómica. Los datos vigentes no se borran si falla.
    with conn.transaction():
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM siac.vuelos_carga WHERE archivo_id=%s", (archivo_id,))
            real = cur.fetchone()[0]
            if real != importados:
                raise RuntimeError(f"Conteo de preparación inesperado: {real} != {importados}")
            cur.execute("""DELETE FROM siac.vuelos_raw WHERE archivo_id IN
                           (SELECT id FROM siac.archivos_importados
                            WHERE nombre_archivo=%s AND id<>%s)""",
                        (nombre, archivo_id))
            columnas = sql.SQL(", ").join(map(sql.Identifier, COLUMNAS))
            cur.execute(sql.SQL("""INSERT INTO siac.vuelos_raw (archivo_id, {})
                                   SELECT archivo_id, {} FROM siac.vuelos_carga
                                   WHERE archivo_id=%s""").format(columnas, columnas),
                        (archivo_id,))
            cur.execute("""UPDATE siac.archivos_importados
                           SET estado='completado', registros_leidos=%s,
                               registros_importados=%s,
                               observaciones='Filtro Año_Local >= 2015 y exclusiones de Power BI'
                           WHERE id=%s""", (leidos, importados, archivo_id))
            cur.execute("DELETE FROM siac.vuelos_carga WHERE archivo_id=%s", (archivo_id,))
    print(f"PUBLICADO: {nombre}: {importados:,} filas válidas.", flush=True)


def importar(conn, ruta):
    nombre, st = ruta.name, ruta.stat()
    print(f"\nRevisando {nombre} ({st.st_size / (1024**3):.2f} GiB)", flush=True)
    digest = firma(ruta)
    archivo_estable(ruta, st)
    trabajo = obtener_trabajo(conn, nombre, st, digest)
    if trabajo is None:
        print("Sin cambios. Se conserva versión publicada.", flush=True)
        return
    archivo_id, leidos, importados = trabajo
    print(f"Carga {archivo_id}. Reanudar desde fila {leidos:,}.", flush=True)
    conteo, lote = 0, []
    with ruta.open("r", encoding="cp1252", newline="") as f:
        lector = csv.reader(f, delimiter=";", quotechar='"', strict=True)
        encabezado = next(lector, None)
        if encabezado != COLUMNAS:
            raise ValueError(f"Encabezado inválido en {nombre}: {encabezado!r}")
        for numero, fila in enumerate(lector, start=1):
            if numero <= leidos:
                continue
            if len(fila) != 47:
                raise ValueError(f"{nombre}: fila {numero+1}: {len(fila)} columnas")
            if incluir(fila, nombre, numero+1):
                lote.append(fila)
            conteo += 1
            if conteo == LOTE:
                leidos += conteo
                importados += len(lote)
                guardar_lote(conn, archivo_id, lote, leidos, importados)
                print(f"  {leidos:,} leídos; {importados:,} cargados en preparación", flush=True)
                conteo, lote = 0, []
        if conteo:
            leidos += conteo
            importados += len(lote)
            guardar_lote(conn, archivo_id, lote, leidos, importados)
    publicar(conn, nombre, archivo_id, leidos, importados, ruta, st, digest)


def main():
    if not CARPETA.is_dir():
        sys.exit("No se encuentra la carpeta de origen. Revisar config_siac.local.json")
    clave = getpass("Contraseña de PostgreSQL: ")
    with psycopg.connect(host=SERVIDOR, port=PUERTO, dbname=BASE,
                         user=USUARIO, password=clave, connect_timeout=15,
                         autocommit=True, application_name="importar_siac_recuperable") as conn:
        preparar(conn)
        for nombre in ARCHIVOS:
            ruta = CARPETA / nombre
            if not ruta.is_file():
                raise FileNotFoundError(f"No se encuentra: {nombre}")
            importar(conn, ruta)
    print("\nTodos los archivos procesados.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        sys.exit(f"ERROR: {exc}")
