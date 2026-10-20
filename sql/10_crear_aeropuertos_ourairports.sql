-- Fuente autoritativa: udseyt-greyf/geodata/fuentes/ourairports.csv
-- CSV separado por ;. Conservar coordenadas como texto: hay formatos mixtos
-- (comillas iniciales, comas y puntos no decimales).
-- No modifica siac.vuelos, siac.vuelos_raw ni la dimensión OACI/IATA histórica.
CREATE TABLE IF NOT EXISTS siac.aeropuertos_ourairports (
    iata text,
    oaci text,
    continent text,
    latitude text,
    longitude text,
    municipality text,
    country text
);

COMMENT ON TABLE siac.aeropuertos_ourairports IS
'Fuente de referencia para equivalencias OACI/IATA y atributos geográficos: geodata/fuentes/ourairports.csv (versión enriquecida).';

-- Siguiente operación (manual, después de crear la tabla):
-- Import/Export Data > Import > CSV > Header: Yes > Delimiter: ;
-- Seleccionar columnas según el encabezado; NO ejecutar COPY desde servidor.
