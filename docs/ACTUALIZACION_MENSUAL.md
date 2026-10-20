# Actualización mensual de Tabla Final.txt

**Documento operativo – 20/10/2026.** Este procedimiento describe la operación manual verificada. Todavía no existe una tarea programada.

## Regla esencial

El proveedor **reemplaza íntegramente** `Tabla Final.txt` cada mes. Además de vuelos nuevos, puede contener modificaciones retroactivas. **No agregar solamente las filas nuevas.** Sustituir la versión completa de ese archivo después de verificar la nueva carga.

Los otros dos archivos son históricos: `Tabla Final_hasta_2019.txt` y `Tabla Final (con encabezados).txt`. El importador comprueba su huella SHA-256 y omite los archivos sin cambios.

## Reglas de exclusión (iguales a Power BI)

| Archivo | Regla |
|---|---|
| Todos | Excluir `Año_Local < 2015` |
| `Tabla Final_hasta_2019.txt` | Excluir año 2019 |
| `Tabla Final (con encabezados).txt` | Excluir 2023, 2024 y 2025 |
| `Tabla Final.txt` | Sin exclusiones adicionales por archivo |

Si aparecen TXT nuevos, **detenerse y definir su prioridad y solapamientos** antes de modificar el importador. La versión documentada solo procesa esos tres nombres.

## Preparación

1. Confirmar que la copia mensual del TXT terminó de escribirse en la carpeta de red.
2. Verificar acceso VPN/red, estabilidad de la unidad compartida y suficiente espacio en el servidor.
3. Conservar una copia segura de la versión previa cuando la política institucional lo permita.
4. Confirmar que la importación anterior figura como `completado` en `siac.archivos_importados`.
5. Guardar un respaldo de PostgreSQL antes de cambios importantes.
6. Ejecutar una sola instancia del importador; no ejecutar otras cargas simultáneas.

## Ejecución desde Windows

Abrir PowerShell en la carpeta donde está `importar_siac_recuperable.py`:

```powershell
py -3 importar_siac_recuperable.py
```

Escribir la contraseña en la consola cuando se solicite. **Nunca guardarla en el repositorio.**

El programa histórico utilizado implementa:
- Lectura `cp1252`, delimitador `;`, comillas dobles y 47 columnas.
- Huella SHA-256 para identificar cambios.
- Procesamiento en lotes de 50.000 filas.
- Tabla de preparación `siac.vuelos_carga` y seguimiento en `siac.archivos_importados`.
- Publicación por archivo en una transacción: elimina filas correspondientes a la versión previa y publica la nueva solo cuando la carga está validada.

**Importante:** los bloques de preparación se confirman; la publicación final sigue siendo una transacción pesada. No cerrar PowerShell mientras esa publicación funciona.

## Qué mensajes esperar

- `Sin cambios. Se conserva versión publicada.`: huella idéntica; no reprocesa.
- `Carga N. Reanudar desde fila X.`: recupera una carga incompleta.
- `... cargados en preparación`: avance; aún **no publicados**.
- `PUBLICADO: Tabla Final.txt: N filas válidas.`: sustitución finalizada.
- `Todos los archivos procesados.`: terminó el recorrido.

## Verificación obligatoria en pgAdmin

Ejecutar `sql/validaciones.sql`. Confirmar:
- Las tres versiones publicadas tienen estado `completado`.
- Las cantidades por archivo corresponden al TXT nuevo.
- El rango de años comienza en 2015.
- No existen versiones de un mismo archivo simultáneamente publicadas.
- Los totales oficiales comparables con Power BI coinciden.
- No hay cargas `procesando` sin explicación.

## Si falla

1. **No borrar** `vuelos_raw`, `vuelos_carga` ni `archivos_importados`.
2. Guardar el mensaje completo y revisar registros de PostgreSQL.
3. Confirmar que la versión anterior permanece `completado`.
4. Si el TXT sigue idéntico, ejecutar de nuevo el importador: puede reanudar.
5. Si el TXT cambió, investigar el estado del intento pendiente antes de reintentar.
6. Si la publicación está ejecutándose, **no iniciar una segunda instancia**.

El error inicial de 19/10/2026 fue `Connection reset by peer` durante un `COPY` monolítico. La solución aplicada fue la importación recuperable.

## Actualización de productos derivados

La vista `siac.vuelos` lee `vuelos_raw` y refleja los datos publicados.

Las **vistas materializadas no se actualizan solas**. Si se crea `siac.pasajeros_mensuales`, efectuar el `REFRESH MATERIALIZED VIEW` después de la publicación y validación. Ejecutarlo solo cuando esté desplegada y probada. Las dimensiones de fecha también deben extenderse a nuevas fechas.

## Seguridad

El repositorio es público: no subir TXT, archivos de datos internos, claves, respaldos, nombres de usuario/host internos ni direcciones de red. Ejecutar las cargas en la red autorizada.


## Procedimiento ejecutable mensual (versión del repositorio)

**Programa:** [scripts/importar_siac_recuperable.py](../scripts/importar_siac_recuperable.py). **Configuración:** [scripts/config_siac.ejemplo.json](../scripts/config_siac.ejemplo.json).

### Preparación inicial en Windows

1. Abrí PowerShell. Comprobá Python con `py -3 --version`.
2. Instalá la dependencia con `py -3 -m pip install "psycopg[binary]"`.
3. Creá una carpeta privada mediante `mkdir "$HOME\\SIAC"`.
4. Descargá ambos archivos desde los enlaces anteriores. Guardalos dentro de esa carpeta.
5. Copiá `config_siac.ejemplo.json` como `config_siac.local.json`.
6. Editá únicamente `config_siac.local.json`. Completá la carpeta compartida, el host, el puerto y el usuario de PostgreSQL. En JSON, duplicá cada barra invertida de las rutas Windows.
7. Guardá `config_siac.local.json` junto a `importar_siac_recuperable.py`. **No compartas ni subas** ese archivo al repositorio. No guardes contraseñas.

### Cada mes

1. Confirmá que terminó de reemplazarse `Tabla Final.txt` en la carpeta compartida.
2. Conservá los otros dos archivos históricos y sus nombres.
3. Abrí PowerShell y ejecutá:

```powershell
cd "$HOME\\SIAC"
py -3 importar_siac_recuperable.py
```

4. Ingresá la contraseña cuando la solicite el programa.
5. Esperá el mensaje `PUBLICADO: Tabla Final.txt: ... filas válidas.` y después `Todos los archivos procesados.`.
6. Confirmá en pgAdmin el estado `completado`, los registros por archivo y la distribución anual. Ejecutá [sql/validaciones.sql](../sql/validaciones.sql).
7. **Actualizá la vista materializada mensual** mediante el procedimiento SQL indicado abajo. Esperá a que termine.
8. Validá los meses, aeropuertos e indicadores mensuales. Compará los valores con Power BI y registrá el resultado.

### Si falla

No borres tablas ni registros. Guardá el error. Revisá `archivos_importados`. Si el archivo no cambió, el programa permite reanudar. Nunca ejecutes dos instancias simultáneas.

**Regla esencial:** el TXT mensual debe reemplazarse **completo**, incluso si contiene correcciones antiguas. Se conservan las exclusiones históricas de Power BI y el límite desde 2015.

**Nota de versión:** el script público se adaptó para obtener la configuración de un archivo local e incluye la corrección de la columna `id` de la tabla de preparación. Aún no se ha probado esta adaptación con la siguiente actualización mensual.


## G. Actualizar el resumen mensual (OBLIGATORIO después de cada publicación)

**Este paso no lo realiza el importador Python.** Ejecutalo únicamente después de confirmar `PUBLICADO` y `estado='completado'`. Si falló la importación, no lo ejecutes.

1. Abrí **pgAdmin → Databases → siga → Query Tool**.
2. Ejecutá **una sola vez**:

```sql
REFRESH MATERIALIZED VIEW siac.pasajeros_mensuales_validos;
```

3. Esperá a que finalice sin errores. Puede demorar por el volumen de vuelos.
4. Verificá la cobertura:

```sql
SELECT COUNT(*) AS registros,
       COUNT(DISTINCT iata) AS aeropuertos,
       MIN(dia_clave_mes) AS primer_mes,
       MAX(dia_clave_mes) AS ultimo_mes
FROM siac.pasajeros_mensuales;
```

5. Verificá el resumen anual de pasajeros y movimientos comerciales:

```sql
SELECT anio_local,
       SUM(pasajeros_ad_total) AS pasajeros_ad_comerciales,
       SUM(vuelos_total) AS movimientos_comerciales
FROM siac.pasajeros_mensuales
WHERE anio_local = 2025
GROUP BY anio_local;
```

**Referencia de validación al 20/10/2026:** 8.094 combinaciones, 57 aeropuertos y meses desde 2015-01-01 hasta 2026-10-01. Para 2025: **50.662.864** pasajeros AD comerciales y **411.926** movimientos comerciales. Estos valores constituyen una referencia de esa carga, **no valores fijos**: las correcciones retroactivas pueden modificarlos.

El resumen comercial utiliza clases `Regular` y `No Regular` y suma `Movimientos` para sus columnas denominadas `vuelos_*`. No lo confundas con los totales de todas las clases de vuelo.

**Si la vista no tiene datos:** el error `materialized view has not been populated` se resuelve ejecutando el mismo `REFRESH MATERIALIZED VIEW`. No requiere recrear la vista.

**Si se agregan meses futuros:** comprobá también la cobertura de `siac.dim_fecha`. La actualización de la vista no amplía automáticamente esa dimensión.


## H. Control de versiones y diferencias (a partir de octubre 2026)

Usar [03_control_versiones.sql](../sql/03_control_versiones.sql) **una sola vez** para instalar las tablas y la función. Luego ejecutar inmediatamente:

```sql
SELECT siac.registrar_version('2026-10-inicial','base');
```

**IMPORTANTE:** el repositorio contiene la instrucción, pero esta captura inicial **no se ejecuta sola**. Ejecutarla antes de la siguiente carga, con los datos actuales. No volver a ejecutarla si ya existe.

La tabla `siac.control_referencia_2025` almacena la referencia comparada con Power BI:
- Pasajeros: 51.117.304
- Pasajeros_AD: 50.806.954
- Pax: 33.537.006
- Pax_AD: 33.356.117,50
- Movimientos: 597.824
- Vuelos: 358.554

### Cada actualización mensual, en orden

1. **ANTES** de ejecutar Python, en pgAdmin, usar un identificador único. Ejemplo noviembre:
   ```sql
   SELECT siac.registrar_version('2026-11','antes');
   ```
2. Ejecutar `py -3 importar_siac_recuperable.py` en Windows. Confirmar `PUBLICADO` y `completado`.
3. **DESPUÉS**, en pgAdmin:
   ```sql
   SELECT siac.registrar_version('2026-11','despues');
   ```
4. Ejecutar [04_comparar_versiones.sql](../sql/04_comparar_versiones.sql), modificando el identificador de versión en las consultas.
5. Examinar diferencias **de todos los años**: pasajeros, vuelos, movimientos y cantidad de registros. Diferencias en años anteriores pueden ser correcciones legítimas o problemas. Investigar antes de aprobar.
6. Examinar las diferencias **mensuales de los últimos doce meses**, incluido el mes actual. Guardar el identificador y el resultado del control.
7. Comprobar duplicación de versiones por archivo y ausencia de años anteriores a 2015.
8. **Solo después** de validar, ejecutar `REFRESH MATERIALIZED VIEW siac.pasajeros_mensuales_validos;`, según la sección G.

La captura de los doce meses se basa en el calendario al momento de ejecutarla. Si un mes no contiene registros, ese mes puede no aparecer en el historial; la vista materializada sí completa los meses por aeropuerto.

**Limitación importante:** este control registra y señala diferencias **después** de publicar. No impide por sí solo la publicación errónea. Para prevenirla, queda pendiente implementar una validación automática de totales y años antes de la transacción de publicación. No interpretes cambios retroactivos como errores sin contrastar la fuente.

Las capturas históricas permanecen en PostgreSQL; el repositorio registra el procedimiento, no los valores confidenciales de cada nueva actualización.


## I. Vista mensual con corte confirmado (validada 20/10/2026)

Se creó **`siac.control_periodo_siac`** y se registró manualmente el corte **2026-09-30** para la versión publicada de `Tabla Final.txt` (archivo_id 4). La vista **`siac.vuelos_validos`** aplica este corte sin borrar los registros originales. La materializada **`siac.pasajeros_mensuales_validos`** utiliza los vuelos válidos y meses hasta el corte confirmado.

**Validación inicial:** 57 aeropuertos, 8.037 combinaciones aeropuerto-mes, enero 2015 a septiembre 2026. Para 2025 se verificaron 50.662.864 pasajeros_AD comerciales y 411.926 movimientos comerciales, iguales a la vista anterior.

### Cada nueva entrega, antes de actualizar el resumen

1. Después de la publicación del TXT, confirmar en `siac.archivos_importados` el `id` nuevo con estado `completado`.
2. Registrar el **corte efectivamente cubierto**. No inferirlo automáticamente de la fecha de entrega: puede haber demoras.
3. Sustituir en el siguiente ejemplo `2026-10-31` por el último día del mes confirmado y revisar las observaciones:

```sql
INSERT INTO siac.control_periodo_siac
  (archivo_id, fecha_actualizacion, fecha_corte, criterio, observaciones)
SELECT id, fecha_modificacion, DATE '2026-10-31', 'manual',
       'Cobertura validada para esta entrega.'
FROM siac.archivos_importados
WHERE nombre_archivo = 'Tabla Final.txt' AND estado = 'completado'
ORDER BY id DESC LIMIT 1
ON CONFLICT (archivo_id) DO NOTHING;
```

4. Verificar la fecha de corte con un `SELECT` antes de continuar. **ATENCIÓN:** `ON CONFLICT DO NOTHING` no modifica un corte ya registrado; si hubo un error, revisarlo y corregirlo expresamente.
5. Ejecutar en pgAdmin:

```sql
REFRESH MATERIALIZED VIEW siac.pasajeros_mensuales_validos;
```

6. Comprobar `MAX(dia_clave_mes)`, número de aeropuertos y totales. Confirmar que no excedan el corte.
7. Registrar las diferencias contra las versiones anteriores y compararlas con Power BI.

**Estado:** conservar la materializada antigua `siac.pasajeros_mensuales` como respaldo temporal. Para consultas actuales usar **`siac.pasajeros_mensuales_validos`**. No se ha sustituido ni eliminado la original. Hay que adaptar `siac.registrar_version` para que los cortes confirmados rijan también el historial; sigue pendiente.


## J. Historial con corte confirmado y doce meses completos (implementación 20/10/2026)

**SQL nuevo:** [05_registrar_version_con_corte.sql](../sql/05_registrar_version_con_corte.sql). Ejecutar **una vez** en pgAdmin, base `siga`. Reemplaza la función, pero no borra la referencia `2026-10-inicial` ni otras capturas.

La función consulta `control_periodo_siac` y utiliza `vuelos_validos`. Registra todos los años. Registra exactamente doce meses terminados en el **corte confirmado**, inclusive si un mes no tiene registros (cero). Las capturas anteriores no se recalculan.

**Orden correcto el próximo mes:**

1. Antes de ejecutar Python: `SELECT siac.registrar_version('2026-11','antes');`. Usa el corte anterior.
2. Ejecutar importador Python y comprobar publicación.
3. Confirmar y guardar el nuevo corte en `control_periodo_siac` para el archivo nuevo. Si hubo demora, declarar el período efectivamente cubierto; no inferirlo de la fecha de entrega.
4. Después: `SELECT siac.registrar_version('2026-11','despues');`. Usa el nuevo corte.
5. Comparar los períodos con [06_comparar_cortes.sql](../sql/06_comparar_cortes.sql), ajustando el identificador.
6. Examinar diferencias para todos los años, incluso años históricos. Comparar meses coincidentes; los meses que salen/entran en la ventana se identifican por separado.
7. Después de validar, ejecutar `REFRESH MATERIALIZED VIEW siac.pasajeros_mensuales_validos;`.

**Cuidado:** el control señala diferencias y duplicaciones, pero aún no bloquea automáticamente una publicación anómala. No borrar o reescribir una captura registrada. Conservar el historial completo en PostgreSQL.
