-- SIAC: conversión geográfica OurAirports, sin modificar datos originales.
-- Basada en parseCoordinateNumber de geodata/js/oferta-demanda.js
-- y en la limpieza del conversor de tabla-operacion-aerolineas-aeropuertos.html.
-- Conserva el signo. Prioriza rango país, luego continente y finalmente rango mundial.
-- La elección del primer candidato válido puede ser ambigua.
CREATE OR REPLACE FUNCTION siac.normalizar_coordenada_geografica(
    valor text,
    tipo text,
    pais text,
    continente text
) RETURNS double precision
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    limpio text;
    digitos text;
    signo integer;
    n numeric;
    candidato double precision;
    respaldo double precision := NULL;
    limite integer;
    rango double precision[];
    cp text := upper(trim(coalesce(pais,'')));
    cc text := upper(trim(coalesce(continente,'')));
    posiciones integer;
BEGIN
    IF valor IS NULL OR tipo NOT IN ('lat','lon') THEN RETURN NULL; END IF;
    limpio := replace(regexp_replace(trim(valor), '^[\x27"]+|[\x27"]+$', '', 'g'), ',', '.');
    limpio := regexp_replace(limpio, '\s+', '', 'g');
    IF limpio = '' OR limpio !~ '^-?[0-9]+(\.[0-9]+)*$' THEN RETURN NULL; END IF;
    limite := CASE WHEN tipo='lat' THEN 90 ELSE 180 END;
    rango := CASE cp
        WHEN 'AR' THEN ARRAY[-56,-21,-74,-52]
        WHEN 'UY' THEN ARRAY[-36,-30,-59,-53]
        WHEN 'PY' THEN ARRAY[-28,-19,-63,-54]
        WHEN 'BR' THEN ARRAY[-35,6,-75,-32]
        WHEN 'CL' THEN ARRAY[-56,-17,-76,-66]
        WHEN 'PE' THEN ARRAY[-19,1,-82,-68]
        WHEN 'BO' THEN ARRAY[-23,-9,-70,-57]
        WHEN 'CO' THEN ARRAY[-5,14,-82,-66]
        WHEN 'EC' THEN ARRAY[-6,2,-82,-75]
        WHEN 'VE' THEN ARRAY[0,13,-74,-59]
        WHEN 'US' THEN ARRAY[18,72,-170,-60]
        WHEN 'MX' THEN ARRAY[14,33,-119,-86]
        WHEN 'PA' THEN ARRAY[7,10,-83,-77]
        WHEN 'DO' THEN ARRAY[17,20,-73,-68]
        WHEN 'CU' THEN ARRAY[19,24,-86,-74]
        WHEN 'ES' THEN ARRAY[35,44.5,-10,5]
        WHEN 'IT' THEN ARRAY[35,48,6,19.5]
        WHEN 'FR' THEN ARRAY[41,52,-6,10]
        WHEN 'NL' THEN ARRAY[50,54,3,8]
        WHEN 'DE' THEN ARRAY[47,56,5,16]
        WHEN 'GB' THEN ARRAY[49,61,-9,2]
        WHEN 'PT' THEN ARRAY[36,43,-10,-6]
        ELSE NULL
    END;
    IF rango IS NULL THEN
        rango := CASE cc
            WHEN 'SA' THEN ARRAY[-60,15,-90,-30]
            WHEN 'NA' THEN ARRAY[5,85,-170,-50]
            WHEN 'EU' THEN ARRAY[34,72,-25,60]
            WHEN 'AF' THEN ARRAY[-40,38,-20,55]
            WHEN 'AS' THEN ARRAY[-10,80,25,180]
            WHEN 'OC' THEN ARRAY[-50,10,110,180]
            WHEN 'AN' THEN ARRAY[-90,-60,-180,180]
            ELSE NULL
        END;
    END IF;

    -- Primer candidato: lectura numérica directa, si corresponde.
    IF limpio ~ '^-?[0-9]+(\.[0-9]+)?$' THEN
        candidato := limpio::double precision;
        IF abs(candidato) <= limite THEN
            IF rango IS NOT NULL AND candidato BETWEEN
                rango[CASE WHEN tipo='lat' THEN 1 ELSE 3 END] AND
                rango[CASE WHEN tipo='lat' THEN 2 ELSE 4 END]
            THEN RETURN candidato; END IF;
            respaldo := candidato;
        END IF;
    END IF;

    signo := CASE WHEN left(limpio,1)='-' THEN -1 ELSE 1 END;
    digitos := regexp_replace(limpio, '[^0-9]', '', 'g');
    IF digitos = '' THEN RETURN respaldo; END IF;
    n := digitos::numeric;
    posiciones := least(length(digitos),16);

    -- Orden idéntico al conversor geográfico de geodata: 0..16 decimales.
    FOR i IN 0..posiciones LOOP
        candidato := (signo * n / power(10::numeric,i))::double precision;
        IF abs(candidato) <= limite THEN
            IF rango IS NOT NULL AND candidato BETWEEN
                rango[CASE WHEN tipo='lat' THEN 1 ELSE 3 END] AND
                rango[CASE WHEN tipo='lat' THEN 2 ELSE 4 END]
            THEN RETURN candidato; END IF;
            IF respaldo IS NULL THEN respaldo := candidato; END IF;
        END IF;
    END LOOP;
    RETURN respaldo;
END;
$$;
