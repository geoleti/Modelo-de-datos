-- SIAC: comprobaciones SOLO LECTURA. Ejecutar en la base siga.
-- Ver versiones y su estado, sin exponer hashes o rutas.
SELECT nombre_archivo, id, estado, registros_leidos, registros_importados, fecha_importacion
FROM siac.archivos_importados ORDER BY nombre_archivo, id DESC;

-- Conteo de filas publicadas por nombre de archivo.
SELECT a.nombre_archivo, COUNT(*) AS registros
FROM siac.vuelos_raw v
JOIN siac.archivos_importados a ON a.id=v.archivo_id
GROUP BY a.nombre_archivo ORDER BY a.nombre_archivo;

-- Control de años y ausencia de registros anteriores a 2015.
SELECT "Año_Local" AS anio, COUNT(*) AS registros
FROM siac.vuelos_raw GROUP BY "Año_Local" ORDER BY "Año_Local";

-- Control de versiones activas por nombre.
SELECT a.nombre_archivo, COUNT(DISTINCT a.id) AS versiones_con_filas
FROM siac.vuelos_raw v
JOIN siac.archivos_importados a ON a.id=v.archivo_id
GROUP BY a.nombre_archivo
HAVING COUNT(DISTINCT a.id) <> 1;

-- Comprobación general con las seis medidas. Los totales 2025 se validaron.
SELECT anio, SUM(pax_num) AS pax, SUM(pax_ad_num) AS pax_ad,
       SUM(pasajeros_num) AS pasajeros, SUM(pasajeros_ad_num) AS pasajeros_ad,
       SUM(movimientos_num) AS movimientos, SUM(vuelos_num) AS vuelos
FROM siac.vuelos WHERE anio=2025 GROUP BY anio;

-- Clasificación de vuelos (registros, no necesariamente movimientos).
SELECT "Clase de Vuelo", COUNT(*) AS registros
FROM siac.vuelos WHERE anio=2025
GROUP BY "Clase de Vuelo" ORDER BY "Clase de Vuelo";
