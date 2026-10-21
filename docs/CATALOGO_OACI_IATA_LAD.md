# Catálogo unificado OACI / IATA / LAD

## Fuente recibida — 21/10/2026

Archivo de la usuaria: `CodigosOACI_IATA_LAD.csv`. El archivo reúne referencias para unificar la búsqueda de destinos SIAC, incluidas ubicaciones LAD. La usuaria indica que es su catálogo más enriquecido hasta ahora y planea actualizarlo periódicamente.

**No confundir** el catálogo enriquecido con `geodata/fuentes/ourairports.csv` ni con `siac."dim_codigos_airport_OACI_IATA_lookup"`. Conservar esas fuentes por trazabilidad. **No sobrescribir datos ni alterar la prioridad de equivalencias hasta definir una regla de resolución entre catálogos**.

### Perfil del archivo

- Delimitador `;`; contiene caracteres no UTF-8 válidos, por lo cual hay que determinar su codificación antes de cargarlo. Se leyó con compatibilidad Latin-1 para inspección; esto no certifica su codificación original.
- Columnas exactas: `id;ident;type;name;latitude_d;longitude_;elevation_;continent;iso_countr;iso_region;municipali;scheduled_;icao_code;iata_code`.
- 11.469 registros.
- `icao_code`: 10.086 valores no vacíos, todos distintos.
- `iata_code`: 9.068 valores no vacíos, todos distintos.
- `ident`: 10.581 valores no vacíos, todos distintos.

| type | Registros |
|---|---:|
| small_airport | 5.551 |
| medium_airport | 4.135 |
| LAD | 888 |
| large_airport | 485 |
| heliport | 256 |
| seaplane_base | 154 |

### Interpretación de LAD

En las **888 filas `type = LAD`**, `icao_code` almacena un **identificador LAD** (no necesariamente un código OACI). Algunos ejemplos comprobados: `176` = EL ADUAR, `245` = EO. 10 NOVIEMBRE, `380` = EA. ALEGRIA. No aplicar validaciones de OACI de cuatro letras a esos casos. Evitar cambiar el nombre `icao_code` dentro del archivo original.

### Decisión confirmada por la usuaria — 21/10/2026

**`CodigosOACI_IATA_LAD.csv` es el catálogo principal y la fuente prioritaria** para búsqueda de aeropuertos y LAD. La usuaria actualiza este archivo y corrige progresivamente las posiciones LAD. Es la única fuente integrada de aeropuertos mundiales y LAD locales. Precedencia: (1) `CodigosOACI_IATA_LAD.csv`, (2) `geodata/fuentes/ourairports.csv` como complemento, (3) `siac."dim_codigos_airport_OACI_IATA_lookup"` como referencia histórica. Los campos de coordenadas pueden permanecer NULL; no eliminar registros ni inventar posiciones. Conservar `icao_code` tal como aparece, incluidos códigos LAD numéricos cuando `type = LAD`. Registrar futuras actualizaciones de la tabla por versión y fuente. Esta decisión documental no constituye una carga ya ejecutada.

### Implementación pendiente

1. Incorporar el archivo como **tabla de catálogo unificado versionable**, independiente del CSV OurAirports ya cargado; preservar columnas y fuente.
2. Aplicar la precedencia confirmada: catálogo LAD principal, CSV OurAirports complementario y dimensión histórica final.
3. Resolver vínculos con `siac.vuelos` priorizando coincidencias reales; conservar registros SIAC sin correspondencia.
4. Revisar codificación y normalización de coordenadas; evitar conversiones directas automáticas.
5. Incorporar procedimiento de actualización periódica con sustitución transaccional de datos del catálogo.

**Estado:** archivo inspeccionado y documentado. **No está cargado aún en PostgreSQL**; no inferir que los 11.469 registros son equivalentes a la dimensión histórica de 10.084 códigos.
