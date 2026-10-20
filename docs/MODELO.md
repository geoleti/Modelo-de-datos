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

## Resumen mensual pendiente

El DAX `PasajerosMensuales_AñoMescompletos` crea combinaciones de **57 aeropuertos × meses de calendario** y calcula pasajeros AD y movimientos comerciales por aterrizaje/despegue y cabotaje/internacional. Usa `Movimientos` para las medidas llamadas «Vuelos». Contiene una media móvil centrada con pesos 0,5 / 1 / 0,5.

Implementar mediante vista materializada tras comprobar su equivalencia con Power BI. Definir cómo representar los meses sin observaciones, diferenciar NULL de cero y actualizar calendario/feriados.

## Dependencias pospuestas

- `CodigosOACI_IATA_LAD.csv` y base LAD: revisión en curso.
- Otros datos aeronáuticos, fuentes web, calendario de feriados y relaciones auxiliares.
- Chatbot: acceso SQL con rol exclusivamente de lectura.

## Seguridad y publicación

Este repositorio es público. Preservar configuración específica del servidor, contraseñas y TXT en recursos institucionales autorizados. El repositorio documenta, pero no copia, la base.
