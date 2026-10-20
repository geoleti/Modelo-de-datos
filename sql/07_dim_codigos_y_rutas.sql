-- DimCodigos_Lookup y RutaCompleta, base siga.
-- Primero cargar las 10.084 equivalencias en la dimensión.
CREATE TABLE IF NOT EXISTS siac.dim_codigos_lookup (
  icao_code text PRIMARY KEY,
  iata_code text
);

CREATE OR REPLACE VIEW siac.vuelos_rutas AS
WITH normalizados AS (
 SELECT v.*,
   NULLIF(NULLIF(NULLIF(upper(btrim(v."Origen OACI")), ''), 'N/A'), 'NA') AS origen_oaci_norm,
   NULLIF(NULLIF(NULLIF(upper(btrim(v."Destino OACI")), ''), 'N/A'), 'NA') AS destino_oaci_norm,
   NULLIF(NULLIF(NULLIF(upper(btrim(v."Origen IATA")), ''), 'N/A'), 'NA') AS origen_iata_norm,
   NULLIF(NULLIF(NULLIF(upper(btrim(v."Destino IATA")), ''), 'N/A'), 'NA') AS destino_iata_norm
 FROM siac.vuelos_validos v
), completos AS (
 SELECT n.*,
   coalesce(n.origen_iata_norm, lo.iata_code, n.origen_oaci_norm) AS "OrigenCompleto",
   coalesce(n.destino_iata_norm, ld.iata_code, n.destino_oaci_norm) AS "DestinoCompleto"
 FROM normalizados n
 LEFT JOIN siac.dim_codigos_lookup lo ON lo.icao_code = n.origen_oaci_norm
 LEFT JOIN siac.dim_codigos_lookup ld ON ld.icao_code = n.destino_oaci_norm
)
SELECT c.*,
 CASE WHEN c."OrigenCompleto" IS NULL OR c."DestinoCompleto" IS NULL THEN NULL
      WHEN c."OrigenCompleto" < c."DestinoCompleto" THEN c."OrigenCompleto" || ' - ' || c."DestinoCompleto"
      ELSE c."DestinoCompleto" || ' - ' || c."OrigenCompleto" END AS "RutaCompleta"
FROM completos c;
