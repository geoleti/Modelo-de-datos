# Modelo conceptual y decisiones

## Origen

`TablaFinalSIAC` agrupa tres TXT mediante Power Query. Las 47 columnas originales siguen disponibles en `siac.vuelos_raw` y `siac.vuelos`; las métricas numéricas derivadas usan sufijos `_num`.

Datos anuales validados: 2015–2026. No inventar equivalencias entre `Pax`, `Pax_AD`, `Pasajeros`, `Pasajeros_AD`, `Vuelos` y `Movimientos`.

## Objetos confirmados

| Objeto | Función |
|---|---|
| `siac.archivos_importados` | Versiones, hash, progreso y estado |
| `siac.vuelos_carga` | Lotes provisionales recuperables |
| `siac.vuelos_raw` | Registros publicados |
| `siac.vuelos` | Vista de columnas originales y conversiones |
| `siac.relaciones_powerbi` | Catálogo documental de 66 relaciones |
| `siac.dim_aeropuerto_sna` | Aeropuertos del SNA |
| `siac.dim_categoria_sna` | Categorías |
| `siac.dim_explotador_sna` | Explotadores |
| `siac.dim_fecha` | Calendario |

## Relaciones

Se documentaron 50 activas y 16 inactivas en Power BI. **No convertirlas directamente en FK**: Power BI define propagación de filtros y puede permitir relaciones inactivas, mientras PostgreSQL implementa `JOIN` y restricciones.

Relaciones destacadas: `AD_IATA` con SNA, origen y destino con sus dimensiones, `Fecha_Local` con TablaFecha, `Hora` con Tabla de horas y matrícula con el inventario de AA2000.

## Catálogo mundial OurAirports y dimensiones Origen/Destino

**Fuente y procedimiento de Power BI, confirmado por la usuaria (20/10/2026):**
- Fuente: [OurAirports](https://ourairports.com/) y su archivo mundial `airports.csv`.
- Se importa el catálogo mundial y **se cruza con los códigos presentes en `TablaFinalSIAC`**. El objetivo es restringir el universo a aeropuertos utilizados como origen o destino en los vuelos SIAC; no utilizar automáticamente todos los aeropuertos mundiales.
- Power BI tiene las consultas `airports`, `airports Origen` y `airports Destinos`. Las dos últimas funcionan como dimensiones de rol, vinculadas a `TablaFinalSIAC[Origen IATA]` y `TablaFinalSIAC[Destino IATA]`, respectivamente.
- En las capturas del editor avanzado, `airports Origen` y `airports Destinos` cargan `https://davidmegginson.github.io/ourairports-data/airports.csv` y filtran `iata_code` no nulo ni vacío; renombran `iata_code`, `name`, `latitude_deg`, `longitude_deg` según el rol. Las capturas muestran error actual por ausencia de la columna `keywords`, referida en `Table.TransformColumnTypes`. Corregir esquema de entrada al actualizar Power BI; no asumir que esta consulta funciona hoy.
- La consulta `airports` mostrada por la usuaria importa una copia **local** de `airports.csv` mediante `Csv.Document(File.Contents(...), [Delimiter=",", Columns=19, Encoding=1252, QuoteStyle=QuoteStyle.None])`, con encabezados promovidos. La ubicación del archivo depende del equipo y no se incorpora al repositorio.
- En PostgreSQL existe `public.aeropuertos_mundo_ourairports_2024` con **78.345 filas y 78.345 códigos `ident` distintos**, sin vacíos, según consulta ejecutada. Esa tabla es un catálogo mundial existente, no el universo restringido de vuelos.
- El archivo `geodata/fuentes/ourairports.csv` es **otra fuente derivada**, de 9.208 filas, usada previamente para comparar códigos OACI/IATA. No confundirlo con `airports.csv` mundial ni con la dimensión `siac."dim_codigos_airport_OACI_IATA_lookup"` de 10.084 códigos.
- De 17 códigos presentes solo en el archivo derivado respecto de `DimCodigos_Lookup`, 16 se encontraron en `public.aeropuertos_mundo_ourairports_2024`; `SAZE:SA` no se encontró. Esto no constituye comparación integral entre ambos catálogos.

**Decisión actualizada (20/10/2026):** utilizar **`udseyt-greyf/geodata/fuentes/ourairports.csv` como fuente geográfica principal**, porque la usuaria confirma que esa versión fue enriquecida. **No utilizar `public.aeropuertos_mundo_ourairports_2024` para las dimensiones SIAC**. Mantener la tabla existente sin modificarla. El cruce de origen y destino se hará con el CSV enriquecido y los códigos utilizados por `siac.vuelos`. Verificar sus columnas y su unicidad antes de implementarlo.

## Resumen mensual pendiente

El DAX `PasajerosMensuales_AñoMescompletos` crea combinaciones de **57 aeropuertos × meses de calendario** y calcula pasajeros AD y movimientos comerciales por aterrizaje/despegue y cabotaje/internacional. Usa `Movimientos` para las medidas llamadas «Vuelos». Contiene una media móvil centrada con pesos 0,5 / 1 / 0,5.

Implementar mediante vista materializada tras comprobar su equivalencia con Power BI. Definir cómo representar los meses sin observaciones, diferenciar NULL de cero y actualizar calendario/feriados.

## Dependencias pospuestas

- `CodigosOACI_IATA_LAD.csv` y base LAD: revisión en curso.
- Otros datos aeronáuticos, fuentes web, calendario de feriados y relaciones auxiliares.
- Chatbot: acceso SQL con rol exclusivamente de lectura.

## Seguridad y publicación

Este repositorio es público. Preservar configuración específica del servidor, contraseñas y TXT en recursos institucionales autorizados. El repositorio documenta, pero no copia, la base.

## Prioridad de equivalencias OACI/IATA

**Decisión de la usuaria (20/10/2026):** considerar **válidas y prioritarias** las equivalencias `oaci` ↔ `iata` de `udseyt-greyf/geodata/fuentes/ourairports.csv`. En caso de discrepancias con `siac."dim_codigos_airport_OACI_IATA_lookup"`, prevalece el CSV enriquecido. Conservar el catálogo anterior como referencia histórica y complemento para códigos ausentes del CSV, sin sobrescribir las equivalencias definidas por él. Adaptar los cálculos de origen, destino y `RutaCompleta` durante una actualización controlada. **Esta decisión queda documentada; todavía no implica que se hayan aplicado cambios SQL.**

## Normalización de coordenadas del CSV enriquecido (revisión de código geodata)

Se identificó uso efectivo del archivo `fuentes/ourairports.csv` en:
- [`js/oferta-demanda.js`](https://github.com/UDSEyT-GREYF/geodata/blob/main/js/oferta-demanda.js), función `parseCoordinateNumber`: elimina apóstrofes y espacios, cambia coma por punto, ensaya desplazamientos de coma decimal y prioriza rangos geográficos configurados por país o continente. Retorna `NaN` si ninguna conversión supera el rango global (latitud ±90°, longitud ±180°).
- [`js/rutasaereas.js`](https://github.com/UDSEyT-GREYF/geodata/blob/main/js/rutasaereas.js), también implementa `parseCoordinateNumber` con rangos geográficos.
- [`tabla-operacion-aerolineas-aeropuertos.html`](https://github.com/UDSEyT-GREYF/geodata/blob/main/tabla-operacion-aerolineas-aeropuertos.html), función `parseCoordinateValue`: elimina comillas/apóstrofes, cambia comas, concatena segmentos después del primer punto y valida rangos globales.

**Precaución:** existen conversores diferentes. La selección del primer candidato dentro de un rango puede ser ambigua; no trasladar automáticamente la lógica JavaScript a una normalización permanente en PostgreSQL. Conservar `latitude`/`longitude` como texto original. Incorporar después campos numéricos derivados con control de rango, país/continente y auditoría de valores ambiguos.
