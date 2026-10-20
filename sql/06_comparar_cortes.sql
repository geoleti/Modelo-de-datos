-- Reemplazar el identificador 2026-11 por la versión utilizada.
-- Comparar períodos anuales.
SELECT COALESCE(a.anio,d.anio) AS anio,
       COALESCE(a.registros,0) AS registros_antes,
       COALESCE(d.registros,0) AS registros_despues,
       COALESCE(d.registros,0)-COALESCE(a.registros,0) AS delta_registros,
       COALESCE(d.pasajeros_ad,0)-COALESCE(a.pasajeros_ad,0) AS delta_pasajeros_ad,
       COALESCE(d.movimientos,0)-COALESCE(a.movimientos,0) AS delta_movimientos,
       COALESCE(d.vuelos,0)-COALESCE(a.vuelos,0) AS delta_vuelos
FROM (SELECT * FROM siac.control_versiones WHERE version='2026-11' AND fase='antes' AND granularidad='anual') a
FULL OUTER JOIN (SELECT * FROM siac.control_versiones WHERE version='2026-11' AND fase='despues' AND granularidad='anual') d
ON a.anio=d.anio
ORDER BY anio;

-- Meses: FULL JOIN conserva meses que entran o salen de la ventana móvil.
SELECT COALESCE(a.anio,d.anio) AS anio,COALESCE(a.mes,d.mes) AS mes,
       a.registros AS registros_antes,d.registros AS registros_despues,
       COALESCE(d.registros,0)-COALESCE(a.registros,0) AS delta_registros,
       COALESCE(d.pasajeros_ad,0)-COALESCE(a.pasajeros_ad,0) AS delta_pasajeros_ad,
       COALESCE(d.movimientos,0)-COALESCE(a.movimientos,0) AS delta_movimientos,
       CASE WHEN a.anio IS NULL THEN 'nuevo_en_ventana'
            WHEN d.anio IS NULL THEN 'sale_de_ventana'
            ELSE 'comparable' END AS situacion
FROM (SELECT * FROM siac.control_versiones WHERE version='2026-11' AND fase='antes' AND granularidad='mensual') a
FULL OUTER JOIN (SELECT * FROM siac.control_versiones WHERE version='2026-11' AND fase='despues' AND granularidad='mensual') d
ON a.anio=d.anio AND a.mes=d.mes
ORDER BY anio,mes;
