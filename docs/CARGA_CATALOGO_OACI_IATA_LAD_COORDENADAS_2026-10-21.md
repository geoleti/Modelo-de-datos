# Carga del catálogo OACI/IATA/LAD y resolución de coordenadas — 21/10/2026

## Estado confirmado
- Base PostgreSQL: `siga`. Esquema: `siac`.
- Tabla principal: `siac.catalogo_oaci_iata_lad`.
- Carga completada con transacción y mensaje `COMMIT`; `SELECT COUNT(*)` devolvió **11.478**.
- Vista geográfica prevista: `siac.catalogo_oaci_iata_lad_geo`.
- Vista independiente `siac.aeropuertos_ourairports_geo`: **visualización mundial confirmada** en Geometry Viewer mediante `SELECT * FROM siac.aeropuertos_ourairports_geo`.
- La captura de Geometry Viewer muestra una **página de resultados**. No debe confundirse con la totalidad de filas.
- No consta todavía una comprobación posterior, completa y específica del conteo de geometrías de la nueva vista `catalogo_oaci_iata_lad_geo`. Registrar esa validación por separado.

## Archivos y fuentes
- Catálogo de origen: `CodigosOACI_IATA_LAD.csv`, enriquecido con siete registros argentinos y coordenadas LAD.
- Excel LAD: `LAD control 21 oct.xlsx`.
- CSV final utilizado para construir el SQL: `CodigosOACI_IATA_LAD_listo_servidor.csv`.
- Script de carga ejecutado: `12_recargar_catalogo_oaci_iata_lad_actualizado.sql`. Su patrón procede de `12_cargar_catalogo_oaci_iata_lad.sql`.
- Mantener `geodata/fuentes/ourairports.csv` y la dimensión histórica de equivalencias como fuentes separadas; no sobrescribirlas.

## Regla indispensable: separador decimal
**Las coordenadas del catálogo deben usar el punto `.` como separador decimal.**
- Incorrecto para carga numérica directa: `-34,5592`; correcto: `-34.5592`.
- Incorrecto: `-58,4156`; correcto: `-58.4156`.
- Las columnas afectadas son exclusivamente `latitude_d` y `longitude_`.
- Conservar el signo negativo, el orden y la precisión disponible.
- Nunca interpretar el punto decimal como separador de miles.
- No quitar indiscriminadamente los puntos ni dividir todas las coordenadas por `10^11`. Esa operación solo era pertinente para otro listado con formato de miles y **no** para el catálogo.
- Evitar volver a aplicar `siac.normalizar_coordenada_geografica` a coordenadas ya corregidas; produjo desplazamientos y conversiones repetidas.

## Codificación de caracteres
- Guardar el archivo CSV en **UTF-8**; utilizar **UTF-8 con BOM** cuando se abra habitualmente desde Excel Windows.
- Separador de columnas del CSV: `;`. Separador decimal de coordenadas: `.`.
- Al importar desde Excel, seleccionar `Datos > Desde texto/CSV`, origen `UTF-8`, delimitador `;`. Importar las columnas de coordenadas como texto cuando Excel pueda reinterpretar el punto decimal según configuración regional.
- Evitar guardar después en ANSI/Windows-1252.
- Se repararon nombres con codificación alterada: ejemplos `San JoaquÃ­n` → `San Joaquín`; `ÅžÄ±rnak Åžerafettin ElÃ§i` → `Şırnak Şerafettin Elçi`; `IÄŸdÄ±r` → `Iğdır`.

## Datos LAD
- El catálogo actualizado incluye coordenadas de la fuente `LAD control 21 oct.xlsx`.
- Regla aplicada al preparar el CSV: priorizar `lat_corregida`/`lon_corregida`; utilizar `lat_fuente`/`lon_fuente` si no hay corrección válida.
- Coincidencias LAD registradas durante el procesamiento: 888; 17 con coordenadas corregidas; 871 con coordenadas de origen.
- Los identificadores LAD de `icao_code` pueden ser numéricos: no imponer validación OACI al tipo `LAD`.

## Procedimiento de carga que funcionó
El servidor no podía acceder directamente al archivo CSV del equipo local mediante el importador de pgAdmin. La solución fue **generar un script SQL local** con los datos escapados e importarlo en Query Tool de pgAdmin.

Esquema de la transacción ejecutada:
```sql
BEGIN;
TRUNCATE TABLE siac.catalogo_oaci_iata_lad;
INSERT INTO siac.catalogo_oaci_iata_lad
    (id, ident, type, name, latitude_d, longitude_, elevation_,
     continent, iso_countr, iso_region, municipali, scheduled_,
     icao_code, iata_code)
VALUES
    (...);
-- Continuar con las 11.478 filas del archivo generado.
COMMIT;
```
**No ejecutar el ejemplo anterior**: `(...)` es un marcador. Usar el script completo conservado como respaldo.
La transacción efectivamente ejecutada terminó con `COMMIT`; la consulta posterior confirmó 11.478 registros.

## Geometría: definición limpia
Cuando las coordenadas del catálogo tengan formato decimal con punto, convertir directamente los valores a `double precision` y construir geometrías:
```sql
-- Expresión para una vista geográfica; no modifica la tabla.
NULLIF(TRIM(c.latitude_d), '')::double precision AS latitud_num,
NULLIF(TRIM(c.longitude_), '')::double precision AS longitud_num,
ST_SetSRID(
  ST_MakePoint(
    NULLIF(TRIM(c.longitude_), '')::double precision,
    NULLIF(TRIM(c.latitude_d), '')::double precision
  ), 4326
)::geometry(Point,4326) AS geom
```
- X = longitud; Y = latitud.
- SRID 4326 (WGS 84).
- Para coordenadas vacías o fuera de rangos válidos, devolver `geom = NULL` mediante `CASE`.
- No hacer que `siac.catalogo_oaci_iata_lad_geo` consulte a sí misma. Esto causó `42P17 infinite recursion`.
- `CREATE OR REPLACE VIEW` no permite quitar ni reordenar columnas existentes (`42P16`). Cuando corresponda reconstruir desde cero, `DROP VIEW` sin `CASCADE`, previa revisión de dependencias.

## Comprobaciones para repetir después de futuras cargas
```sql
SELECT COUNT(*) AS filas FROM siac.catalogo_oaci_iata_lad;

SELECT
    COUNT(*) AS registros,
    COUNT(geom) AS con_geometria,
    COUNT(*) FILTER (WHERE type = 'LAD') AS lad
FROM siac.catalogo_oaci_iata_lad_geo;

SELECT icao_code, iata_code, latitude_d, longitude_,
       latitud_num, longitud_num, ST_AsText(geom) AS wkt
FROM siac.catalogo_oaci_iata_lad_geo
WHERE icao_code IN ('SABE', 'SAEZ', 'SASA');
```
Revisar además la extensión global en QGIS/PostGIS. En pgAdmin, Geometry Viewer visualiza los puntos del conjunto de filas/página mostrado, no necesariamente todos los puntos.

## Próxima etapa del modelo SIAC
1. Validar `catalogo_oaci_iata_lad_geo` y las filas con coordenadas fuera de rango.
2. Identificar claves y duplicidades de los códigos OACI/IATA antes de relacionarlas con las dimensiones y los vuelos.
3. Conservar `siac.catalogo_oaci_iata_lad` como fuente prioritaria; mantener las dimensiones y OurAirports como referencias complementarias.
4. Documentar cualquier actualización con fecha, total de filas, origen y resultado de la comprobación.

## Resultado y límites
**Confirmado:** carga de 11.478 filas y mapa mundial de la vista OurAirports. **Pendiente de confirmar:** recuento geográfico integral de la nueva vista del catálogo y equivalencias finales del modelo SIAC.

## Validación geográfica confirmada — 21/10/2026
Consulta ejecutada por la usuaria sobre `siac.catalogo_oaci_iata_lad_geo`:
- Total: **11.478**.
- Con `geom`: **11.476**.
- Sin `geom`: **2**.
- Total LAD: **888**.
- LAD con `geom`: **888**.
- Cobertura: **99,98 %**.
La identificación de los dos registros sin geometría queda pendiente. Consulta:
```sql
SELECT id, icao_code, iata_code, name, type, latitude_d, longitude_
FROM siac.catalogo_oaci_iata_lad_geo
WHERE geom IS NULL;
```
