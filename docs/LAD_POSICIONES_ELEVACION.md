# Posiciones y elevaciones LAD

Fuente recibida: `lad_control_posicion_2026-10-21.csv`.

Registros: **892**; claves `Registro` distintas: **892**.

Tipos: LAD 774, LADH 114, LAD/LADH 3, LADA 1.

Coordenadas corregidas completas: **17**. Elevaciones informadas: **891**.

**Correspondencia:** `Registro` del archivo = `icao_code` del catálogo `siac.catalogo_oaci_iata_lad`, para registros LAD.

**Precedencia espacial:** coordenada corregida, coordenada fuente LAD, coordenada original del catálogo. Preservar todas las columnas originales. Elevación original como texto y derivación numérica cuando proceda.

El archivo original no se publica en GitHub. Se prepara un SQL de carga privada de 892 registros y una vista PostGIS `siac.catalogo_oaci_iata_lad_geo`, pendientes de ejecución.

Después se compararán las coordenadas del catálogo principal con OurAirports. No modificar `geodata` ni los vuelos originales.
