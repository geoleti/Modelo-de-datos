-- Extender siac.vuelos con columnas Power Query y DAX, sin crear otra vista.
-- Ejecutar una sola vez. No modifica datos de siac.vuelos_raw.
-- Conserva la definición y el orden de las columnas existentes.
DO $block$
DECLARE
  definicion text;
  consulta text;
BEGIN
 IF EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='siac' AND table_name='vuelos' AND column_name='RutaCompleta'
 ) THEN
   RAISE NOTICE 'RutaCompleta ya existe en siac.vuelos. No se realizan cambios.';
   RETURN;
 END IF;

 IF to_regclass('siac."dim_codigos_airport_OACI_IATA_lookup"') IS NULL THEN
   RAISE EXCEPTION 'Falta siac."dim_codigos_airport_OACI_IATA_lookup"';
 END IF;

 definicion := regexp_replace(pg_get_viewdef('siac.vuelos'::regclass, true), ';\s*$', '');
 consulta := format($view$
 CREATE OR REPLACE VIEW siac.vuelos AS
 WITH original AS (
   %s
 ),
 normalizado AS (
 SELECT v.*,
   NULLIF(NULLIF(NULLIF(UPPER(BTRIM(v."Origen OACI")),''),'NA'),'N/A') AS origen_oaci_normalizado,
   NULLIF(NULLIF(NULLIF(UPPER(BTRIM(v."Destino OACI")),''),'NA'),'N/A') AS destino_oaci_normalizado,
   NULLIF(NULLIF(NULLIF(UPPER(BTRIM(v."Origen IATA")),''),'NA'),'N/A') AS origen_iata_normalizado,
   NULLIF(NULLIF(NULLIF(UPPER(BTRIM(v."Destino IATA")),''),'NA'),'N/A') AS destino_iata_normalizado,
   CASE WHEN v."Clase de Vuelo" IN ('Regular','No Regular')
        THEN 'Comercial' ELSE 'Av. General' END AS comercial_general_calculado,
   CASE WHEN NULLIF(BTRIM(v."Aerolinea Asientos"),'') ~ '^-?[0-9]+([.,][0-9]+)?$'
        THEN replace(BTRIM(v."Aerolinea Asientos"),',','.')::numeric END AS asientos_calculados,
   CASE WHEN NULLIF(BTRIM(v."DistanciaKM"),'') ~ '^-?[0-9]+([.,][0-9]+)?$'
        THEN replace(BTRIM(v."DistanciaKM"),',','.')::numeric END AS distancia_calculada
 FROM original v
 ),
 completo AS (
 SELECT n.*,
    COALESCE(n.origen_iata_normalizado, NULLIF(UPPER(BTRIM(lo.iata_code)),''), n.origen_oaci_normalizado) AS origen_completo_calculado,
    COALESCE(n.destino_iata_normalizado, NULLIF(UPPER(BTRIM(ld.iata_code)),''), n.destino_oaci_normalizado) AS destino_completo_calculado
 FROM normalizado n
 LEFT JOIN siac."dim_codigos_airport_OACI_IATA_lookup" lo ON lo.icao_code=n.origen_oaci_normalizado
 LEFT JOIN siac."dim_codigos_airport_OACI_IATA_lookup" ld ON ld.icao_code=n.destino_oaci_normalizado
 ),
 derivado AS (
 SELECT c.*,
    (c.asientos_calculados * c.distancia_calculada) AS ask_calculado,
    (c.pasajeros_ad_num * c.distancia_calculada) AS rpk_calculado
 FROM completo c
 )
 SELECT
 -- Mantener solo columnas originales antes de las columnas nuevas:
 %s,
 d.origen_completo_calculado AS "OrigenCompleto",
 d.destino_completo_calculado AS "DestinoCompleto",
 CASE WHEN d.origen_completo_calculado IS NULL OR d.destino_completo_calculado IS NULL THEN NULL
      WHEN d.origen_completo_calculado < d.destino_completo_calculado
      THEN d.origen_completo_calculado || ' - ' || d.destino_completo_calculado
      ELSE d.destino_completo_calculado || ' - ' || d.origen_completo_calculado END AS "RutaCompleta",
 CASE WHEN d."Origen IATA" < d."Destino IATA"
      THEN d."Origen IATA" || ' - ' || d."Destino IATA"
      ELSE d."Destino IATA" || ' - ' || d."Origen IATA" END AS "CityPair_IATA",
 d.comercial_general_calculado AS "Clase de vuelo Comercial Av. Gral",
 d.comercial_general_calculado || ' - ' || COALESCE(d."Clasificación Vuelo",'') AS "Clase del vuelo y region",
 COALESCE(d."Clasificación Vuelo",'') || ' - ' || COALESCE(d."Clase de Vuelo",'') AS "Clase y tipo de vuelo",
 COALESCE(d."Clasificación Vuelo",'') || ' - ' || COALESCE(d."Tipo de Movimiento",'')
 || ' (' || CASE
      WHEN d."Tipo de Movimiento"='Aterrizaje' THEN 'pasajeros arribados'
      WHEN d."Tipo de Movimiento"='Despegue' THEN 'pasajeros partidos'
      ELSE 'otro movimiento' END || ')' AS "Clasificacion del vuelo y tipo de movimiento",
 COALESCE(d."Tipo de Movimiento",'') || ' - ' || COALESCE(d."Clasificación Vuelo",'')
     AS "Tipo y clasificación de vuelo",
 CASE
   WHEN BTRIM(d."Clasificación Vuelo")='Cabotaje' AND BTRIM(d."Clase de Vuelo")='Regular' THEN 'Regular Cabotaje'
   WHEN BTRIM(d."Clasificación Vuelo")='Internacional' AND BTRIM(d."Clase de Vuelo")='Regular' THEN 'Regular Internacional'
   WHEN BTRIM(d."Clasificación Vuelo")='Cabotaje' AND BTRIM(d."Clase de Vuelo")='No Regular' THEN 'No Regular Cabotaje'
   WHEN BTRIM(d."Clasificación Vuelo")='Internacional' AND BTRIM(d."Clase de Vuelo")='No Regular' THEN 'No Regular Internacional'
   WHEN BTRIM(d."Clasificación Vuelo")='Cabotaje' THEN 'Av. Gral Cabotaje'
   WHEN BTRIM(d."Clasificación Vuelo")='Internacional' THEN 'Av. Gral Internacional'
 END AS "Clase de vuelo regular o no regular y av. gral",
 CASE
   WHEN so.iata IS NULL OR sd.iata IS NULL THEN 'Fuera del SNA'
   WHEN UPPER(BTRIM(COALESCE(d."Tipo de Movimiento",'')))='DESPEGUE' THEN 'SNA - Despegue'
   WHEN UPPER(BTRIM(COALESCE(d."Tipo de Movimiento",'')))='ATERRIZAJE' THEN 'SNA - Aterrizaje'
   ELSE 'SNA - Movimiento no identificado'
 END AS "Clasificación SNA Movimiento",
 d.ask_calculado AS "ASK del vuelo",
 d.rpk_calculado AS "RPK del vuelo",
 d.rpk_calculado / NULLIF(d.ask_calculado,0) AS "Ocupacion del vuelo",
 CASE WHEN d.asientos_calculados IS NULL THEN 'FALTA ASIENTO'
      WHEN d.pasajeros_ad_num > d.asientos_calculados THEN 'PASAJEROS > ASIENTOS'
      ELSE 'OK' END AS "Faltan_Asientos",
 CASE WHEN UPPER(BTRIM(COALESCE(d."Origen IATA",''))) IN ('AEP','EZE','EPA','FDO')
           OR UPPER(BTRIM(COALESCE(d."Destino IATA",''))) IN ('AEP','EZE','EPA','FDO')
      THEN 'AMBA' ELSE 'sin pasar por AMBA' END AS "AMBA-Provincias",
 CASE WHEN d.anio IS NOT NULL AND d.mes IS NOT NULL
      THEN d.anio::text || '-' || LPAD(d.mes::text,2,'0') END AS "Año-mes",
 REPLACE(d."Matrícula",'-','') AS "Matrícula1",
 d.fecha_hora::time AS "HoraCompleta",
 date_trunc('hour', d.fecha_hora)::time AS "Hora"
 FROM derivado d
 LEFT JOIN siac.dim_aeropuerto_sna so ON UPPER(BTRIM(so.iata))=d.origen_iata_normalizado
 LEFT JOIN siac.dim_aeropuerto_sna sd ON UPPER(BTRIM(sd.iata))=d.destino_iata_normalizado
 $view$, definicion,
   (SELECT string_agg(format('d.%I', a.attname), ', ' ORDER BY a.attnum)
    FROM pg_attribute a
    WHERE a.attrelid='siac.vuelos'::regclass
      AND a.attnum>0 AND NOT a.attisdropped));
 EXECUTE consulta;
 RAISE NOTICE 'Vista siac.vuelos ampliada sin cambiar sus columnas originales.';
END;
$block$;
