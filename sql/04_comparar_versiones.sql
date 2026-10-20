-- 1) Antes de actualizar TXT (usar identificador nuevo cada mes):
-- SELECT siac.registrar_version('2026-11', 'antes');
-- 2) Ejecutar importador Python y confirmar PUBLICADO.
-- 3) Después de publicar:
-- SELECT siac.registrar_version('2026-11', 'despues');

-- Comparación anual. REEMPLAZAR 2026-11 por identificador utilizado.
SELECT d.anio,
       d.registros-a.registros AS diferencia_registros,
       d.pasajeros-a.pasajeros AS diferencia_pasajeros,
       d.pasajeros_ad-a.pasajeros_ad AS diferencia_pasajeros_ad,
       d.movimientos-a.movimientos AS diferencia_movimientos,
       d.vuelos-a.vuelos AS diferencia_vuelos
FROM siac.control_versiones d
JOIN siac.control_versiones a
  ON a.version=d.version AND a.granularidad=d.granularidad
 AND a.anio=d.anio AND a.mes=d.mes AND a.fase='antes'
WHERE d.version='2026-11' AND d.fase='despues'
  AND d.granularidad='anual'
ORDER BY d.anio;

-- Comparación mensual de los últimos 12 meses.
SELECT d.anio,d.mes,
       d.registros-a.registros AS diferencia_registros,
       d.pasajeros_ad-a.pasajeros_ad AS diferencia_pasajeros_ad,
       d.movimientos-a.movimientos AS diferencia_movimientos,
       d.vuelos-a.vuelos AS diferencia_vuelos
FROM siac.control_versiones d
JOIN siac.control_versiones a
  ON a.version=d.version AND a.granularidad=d.granularidad
 AND a.anio=d.anio AND a.mes=d.mes AND a.fase='antes'
WHERE d.version='2026-11' AND d.fase='despues'
  AND d.granularidad='mensual'
ORDER BY d.anio,d.mes;

-- Control contra línea base 2025 (suma de todas las clases).
SELECT b.anio,
       SUM(v.pasajeros_num)-b.pasajeros AS delta_pasajeros,
       SUM(v.pasajeros_ad_num)-b.pasajeros_ad AS delta_pasajeros_ad,
       SUM(v.pax_num)-b.pax AS delta_pax,
       SUM(v.pax_ad_num)-b.pax_ad AS delta_pax_ad,
       SUM(v.movimientos_num)-b.movimientos AS delta_movimientos,
       SUM(v.vuelos_num)-b.vuelos AS delta_vuelos
FROM siac.control_referencia_2025 b
JOIN siac.vuelos v ON v.anio=b.anio
GROUP BY b.anio,b.pasajeros,b.pasajeros_ad,b.pax,b.pax_ad,b.movimientos,b.vuelos;

-- Detectar versiones duplicadas activas por archivo.
SELECT a.nombre_archivo,COUNT(DISTINCT a.id) AS versiones_publicadas
FROM siac.vuelos_raw v
JOIN siac.archivos_importados a ON a.id=v.archivo_id
GROUP BY a.nombre_archivo
HAVING COUNT(DISTINCT a.id)<>1;

-- Detectar años anteriores a 2015.
SELECT COUNT(*) AS registros_anteriores_2015
FROM siac.vuelos
WHERE anio < 2015;
