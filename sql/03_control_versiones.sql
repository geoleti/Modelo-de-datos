-- Ejecutar una sola vez en pgAdmin, base siga. No modifica vuelos_raw.
CREATE TABLE IF NOT EXISTS siac.control_referencia_2025 (
    anio integer PRIMARY KEY,
    pasajeros numeric NOT NULL,
    pasajeros_ad numeric NOT NULL,
    pax numeric NOT NULL,
    pax_ad numeric NOT NULL,
    movimientos numeric NOT NULL,
    vuelos numeric NOT NULL,
    descripcion text NOT NULL
);
INSERT INTO siac.control_referencia_2025
(anio,pasajeros,pasajeros_ad,pax,pax_ad,movimientos,vuelos,descripcion)
VALUES (2025,51117304,50806954,33537006,33356117.50,597824,358554,
        'Power BI y PostgreSQL coincidentes en carga octubre 2026')
ON CONFLICT (anio) DO NOTHING;

CREATE TABLE IF NOT EXISTS siac.control_versiones (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version text NOT NULL,
    fase text NOT NULL CHECK (fase IN ('antes','despues','base')),
    granularidad text NOT NULL CHECK (granularidad IN ('anual','mensual')),
    anio integer NOT NULL,
    mes integer NOT NULL DEFAULT 0 CHECK (mes BETWEEN 0 AND 12),
    capturado_en timestamptz NOT NULL DEFAULT now(),
    registros bigint NOT NULL,
    pasajeros numeric,
    pasajeros_ad numeric,
    pax numeric,
    pax_ad numeric,
    movimientos numeric,
    vuelos numeric,
    UNIQUE (version, fase, granularidad, anio, mes),
    CHECK ((granularidad='anual' AND mes=0)
        OR (granularidad='mensual' AND mes BETWEEN 1 AND 12))
);

CREATE OR REPLACE FUNCTION siac.registrar_version(p_version text, p_fase text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_version IS NULL OR btrim(p_version) = '' OR
     p_fase NOT IN ('antes','despues','base') THEN
     RAISE EXCEPTION 'Versión o fase incorrecta';
  END IF;
  IF EXISTS (SELECT 1 FROM siac.control_versiones
             WHERE version=p_version AND fase=p_fase) THEN
     RAISE EXCEPTION 'Esta versión y fase ya fueron registradas: %, %',p_version,p_fase;
  END IF;

  INSERT INTO siac.control_versiones
    (version,fase,granularidad,anio,mes,registros,pasajeros,pasajeros_ad,
     pax,pax_ad,movimientos,vuelos)
  SELECT p_version,p_fase,'anual',anio,0,COUNT(*),
         SUM(pasajeros_num),SUM(pasajeros_ad_num),
         SUM(pax_num),SUM(pax_ad_num),SUM(movimientos_num),SUM(vuelos_num)
  FROM siac.vuelos
  GROUP BY anio;

  -- Últimos 12 meses, incluido el mes calendario actual.
  INSERT INTO siac.control_versiones
    (version,fase,granularidad,anio,mes,registros,pasajeros,pasajeros_ad,
     pax,pax_ad,movimientos,vuelos)
  SELECT p_version,p_fase,'mensual',anio,mes,COUNT(*),
         SUM(pasajeros_num),SUM(pasajeros_ad_num),
         SUM(pax_num),SUM(pax_ad_num),SUM(movimientos_num),SUM(vuelos_num)
  FROM siac.vuelos
  WHERE make_date(anio,mes,1) BETWEEN
        (date_trunc('month',current_date)::date - interval '11 months')::date
        AND date_trunc('month',current_date)::date
  GROUP BY anio,mes;
END $$;

-- Primera captura: ejecutar AHORA, ANTES de reemplazar Tabla Final.txt.
-- Ejecutar sólo una vez para esta versión:
-- SELECT siac.registrar_version('2026-10-inicial', 'base');
