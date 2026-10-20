# Registro cronológico del proyecto

## 19/10/2026: creación de base y carga histórica

1. Se comprobó pgAdmin sobre PostgreSQL/PostGIS 16.9.
2. Se creó el esquema `siac` dentro de la base `siga`.
3. Se identificaron **tres TXT** de aproximadamente 1,08–1,21 GB cada uno, total ~3,1 GB.
4. Se recuperó Power Query de `TablaFinalSIAC`: 47 columnas, separador `;`, codificación Windows-1252, encabezados y formatos numéricos con coma decimal.
5. Se identificaron exclusiones históricas por nombre de archivo y año.
6. Se instalaron `psycopg` y `psycopg-binary` para Python 3.
7. Se verificó conexión directa desde Windows con PostgreSQL.
8. Se crearon `siac.archivos_importados` y `siac.vuelos_raw`.
9. Primer importador: el archivo histórico se publicó con **2.285.580** registros; falló la segunda carga masiva durante `COPY`.
10. Los logs mostraron `Connection reset by peer`, `unexpected EOF` y checkpoints prolongados. El servidor no se reinició.
11. Se adoptó el importador recuperable con lotes de 50.000, `vuelos_carga` y publicación transaccional.
12. Se corrigió una restricción `NOT NULL` de `id` en la tabla de preparación; el flujo pudo continuar.
13. Se publicaron **1.616.386** filas de `Tabla Final (con encabezados).txt` y **2.152.987** de `Tabla Final.txt`.
14. Total publicado: **6.054.953** filas desde 2015 hasta 2026.
15. Se creó la vista `siac.vuelos` con las 47 columnas originales y conversiones numéricas y temporales.

### Control 2025 versus Power BI

| Indicador | Resultado |
|---|---:|
| Movimientos | 597.824 |
| Vuelos | 358.554 |
| Pasajeros | 51.117.304 |
| Pasajeros_AD | 50.806.954 |
| Pax | 33.537.006 |
| Pax_AD | 33.356.117,50 |

Los seis totales coinciden con Power BI (Pax_AD aparece redondeado en el visual). Estos totales incluyen todas las clases de vuelo; **no deben interpretarse automáticamente como pasajeros comerciales**.

## 20/10/2026: metadatos y dimensiones

1. Se extrajeron consultas y particiones desde DAX Studio.
2. Se relevaron fuentes de archivos y servicios web de Power BI.
3. Se identificaron 19 columnas DAX calculadas en la tabla principal.
4. Se exportaron **66 relaciones** y sus columnas: 50 activas, 16 inactivas.
5. Se cargó el catálogo documental `siac.relaciones_powerbi`. No se añadieron claves foráneas.
6. Se crearon `dim_aeropuerto_sna`, `dim_categoria_sna` y `dim_explotador_sna` con **57 registros** cada una.
7. Se creó `dim_fecha` con **4.311 registros**.
8. Se revisó el DAX de `PasajerosMensuales_AñoMescompletos`. El resumen mensual quedó **planificado**, no confirmado como creado.
9. Se pospuso `CodigosOACI_IATA_LAD.csv` por revisión del conjunto LAD.

## Problemas y soluciones

- **Error de sintaxis por SQL parcial:** cargar y ejecutar el script completo; no copiar solo las primeras filas de `INSERT`.
- **Error de COPY monolítico:** utilizar lotes recuperables.
- **`id NOT NULL` en `vuelos_carga`:** se corrigió durante la implementación. Debe revisarse en una instalación nueva.
- **Demora del INSERT final:** se observaron esperas `WALWrite` y `WALSync`. No cancelar una transacción activa sin diagnóstico.

## Pendientes

- Revisar y versionar scripts exactos ya ejecutados, sin direcciones internas ni secretos.
- Reproducir expresiones DAX y relaciones como consultas/vistas SQL; verificar unicidad.
- Integrar fuentes auxiliares restantes y feriados.
- Crear y validar resumen mensual por aeropuerto.
- Crear rol restringido y chatbot de consulta.
