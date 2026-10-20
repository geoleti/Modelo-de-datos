-- SIAC: reemplazo seguro de registrar_version. No borra capturas existentes.
-- Ejecutar en pgAdmin sobre base siga, esquema siac.
CREATE OR REPLACE FUNCTION siac.registrar_version(p_version text, p_fase text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_corte date;
BEGIN
    IF p_version IS NULL OR btrim(p_version) = ''
       OR p_fase IS NULL OR p_fase NOT IN ('antes','despues','base') THEN
        RAISE EXCEPTION 'Versión o fase inválida';
    END IF;

    SELECT c.fecha_corte INTO v_corte
    FROM siac.control_periodo_siac c
    JOIN siac.archivos_importados a ON a.id = c.archivo_id
    WHERE a.nombre_archivo='Tabla Final.txt' AND a.estado='completado'
    ORDER BY a.id DESC LIMIT 1;

    IF v_corte IS NULL THEN
        RAISE EXCEPTION 'Registrar fecha de corte para la versión publicada de Tabla Final.txt antes de capturar';
    END IF;

    IF EXISTS (SELECT 1 FROM siac.control_versiones
               WHERE version=p_version AND fase=p_fase) THEN
        RAISE EXCEPTION 'Captura ya existe para versión % y fase %',p_version,p_fase;
    END IF;

    -- Conserva todos los años válidos, no solo últimos doce meses.
    INSERT INTO siac.control_versiones
      (version,fase,granularidad,anio,mes,registros,pasajeros,pasajeros_ad,pax,pax_ad,movimientos,vuelos)
    SELECT p_version,p_fase,'anual',anio,0,COUNT(*),
           SUM(pasajeros_num),SUM(pasajeros_ad_num),
           SUM(pax_num),SUM(pax_ad_num),SUM(movimientos_num),SUM(vuelos_num)
    FROM siac.vuelos_validos
    GROUP BY anio;

    -- Grilla de doce meses incluyendo meses sin registros.
    WITH meses AS (
        SELECT gs::date AS inicio
        FROM generate_series(
            date_trunc('month',v_corte)::date - interval '11 months',
            date_trunc('month',v_corte)::date,
            interval '1 month'
        ) AS gs
    ), indicadores AS (
        SELECT make_date(anio,mes,1) AS inicio,
               COUNT(*) AS registros,
               SUM(pasajeros_num) AS pasajeros,
               SUM(pasajeros_ad_num) AS pasajeros_ad,
               SUM(pax_num) AS pax,
               SUM(pax_ad_num) AS pax_ad,
               SUM(movimientos_num) AS movimientos,
               SUM(vuelos_num) AS vuelos
        FROM siac.vuelos_validos
        WHERE make_date(anio,mes,1) BETWEEN
             date_trunc('month',v_corte)::date - interval '11 months'
             AND date_trunc('month',v_corte)::date
        GROUP BY anio,mes
    )
    INSERT INTO siac.control_versiones
      (version,fase,granularidad,anio,mes,registros,pasajeros,pasajeros_ad,pax,pax_ad,movimientos,vuelos)
    SELECT p_version,p_fase,'mensual',
           extract(year from m.inicio)::int,extract(month from m.inicio)::int,
           coalesce(i.registros,0),coalesce(i.pasajeros,0),
           coalesce(i.pasajeros_ad,0),coalesce(i.pax,0),coalesce(i.pax_ad,0),
           coalesce(i.movimientos,0),coalesce(i.vuelos,0)
    FROM meses m LEFT JOIN indicadores i USING (inicio);
END $$;

-- No ejecutar ahora registrar_version('2026-10-inicial','base'):
-- ya está registrado. El primer uso será 'antes' de la próxima carga.
