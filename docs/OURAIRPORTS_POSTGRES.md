# OurAirports enriquecido en PostgreSQL — implementación confirmada

Fecha: 20/10/2026. Base `siga`, esquema `siac`.

## Fuente y alcance

- CSV autoritativo: [geodata/fuentes/ourairports.csv](https://github.com/UDSEyT-GREYF/geodata/blob/main/fuentes/ourairports.csv), separador `;`, siete columnas: `iata;oaci;continent;latitude;longitude;municipality;country`.
- Priorizar sus equivalencias OACI/IATA. Mantener `siac."dim_codigos_airport_OACI_IATA_lookup"` como complemento histórico.
- No utilizar `public.aeropuertos_mundo_ourairports_2024` para el modelo SIAC. No modificar `geodata`.

## Tabla e importación

- `siac.aeropuertos_ourairports` creada mediante `sql/10_crear_aeropuertos_ourairports.sql`.
- Coordenadas `latitude` y `longitude` almacenadas como **texto** para preservar originales.
- Descarga y carga **desde el equipo Windows del usuario**, dado que pgAdmin no accede a archivos locales del servidor.
- Importación preparada con PowerShell, `Import-Csv -Delimiter ';'`; 9.208 `INSERT` en un SQL con `BEGIN; TRUNCATE; ... COMMIT;`.
- Script local `10_cargar_ourairports.sql` ejecutado por `py -3 .\ejecutar_sql_siac.py .\10_cargar_ourairports.sql`. La primera ejecución falló por marca UTF-8 BOM antes de `BEGIN`; se guardó sin BOM y la segunda terminó con «SQL ejecutado correctamente».
- Consulta confirmada: **9.208 filas, 8.054 códigos IATA distintos y 8.225 códigos OACI distintos**.

## Coordenadas y PostGIS

- Conversor inicial `siac.normalizar_coordenada(valor,tipo)`, para comillas, coma decimal, varios puntos y límites latitud ±90°, longitud ±180°.
- Conversor geográfico `siac.normalizar_coordenada_geografica(valor,tipo,pais,continente)` documentado en [sql/11_normalizar_coordenadas_geografia.sql](../sql/11_normalizar_coordenadas_geografia.sql). Emplea rangos de país/continente y reconstrucción decimal basados en funciones del proyecto `geodata`.
- Vista `siac.aeropuertos_ourairports_geo`: códigos y coordenadas originales; `latitud_num` y `longitud_num`; columna **`geom geometry(Point,4326)`**, generada con `ST_SetSRID(ST_MakePoint(longitud_num,latitud_num),4326)` cuando ambas son válidas.
- Resultado consultado: **9.207 registros con ambas coordenadas numéricas y 1 pendiente**. Cobertura aproximadamente 99,99 %.
- Visualización realizada por el usuario en **Geometry Viewer de pgAdmin**, con distribución mundial de puntos razonable a escala general. Esto **no garantiza precisión individual**: persisten posibles ambigüedades decimales.
- `siac.vuelos`, `siac.vuelos_raw` y `geodata` no fueron modificados por esta operación.

## Relación con SIAC: pendiente

- Derivar subconjuntos por aeropuertos realmente utilizados en `siac.vuelos`; dimensiones de rol origen y destino.
- Comprobar unicidad de las claves usadas en las uniones para evitar duplicar movimientos.
- Incorporar prioridad OACI/IATA del CSV a `OrigenCompleto`, `DestinoCompleto` y `RutaCompleta` de forma controlada. El renombrado y cambio de prioridad anterior todavía no garantiza que todas las fórmulas SQL ya utilicen el nuevo catálogo.
- No crear claves foráneas por copia automática de relaciones de Power BI.

## SQL de vista geográfica (para repositorio)

```sql
CREATE OR REPLACE VIEW siac.aeropuertos_ourairports_geo AS
SELECT
    iata, oaci, continent, municipality, country, latitude, longitude,
    siac.normalizar_coordenada_geografica(latitude, 'lat', country, continent) AS latitud_num,
    siac.normalizar_coordenada_geografica(longitude, 'lon', country, continent) AS longitud_num,
    CASE
        WHEN siac.normalizar_coordenada_geografica(latitude, 'lat', country, continent) IS NOT NULL
         AND siac.normalizar_coordenada_geografica(longitude, 'lon', country, continent) IS NOT NULL
        THEN ST_SetSRID(ST_MakePoint(
           siac.normalizar_coordenada_geografica(longitude, 'lon', country, continent),
           siac.normalizar_coordenada_geografica(latitude, 'lat', country, continent)
        ),4326)::geometry(Point,4326)
        ELSE NULL
    END AS geom
FROM siac.aeropuertos_ourairports;
```
