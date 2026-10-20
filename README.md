# Modelo de datos SIAC

Documentación técnica de la migración del modelo **SIAC de Power BI a PostgreSQL/PostGIS**, iniciada en octubre de 2026.

> **Estado: implementación parcial, en validación.** El repositorio documenta el procedimiento. No contiene los TXT originales, contraseñas ni respaldos de PostgreSQL.

## Estado alcanzado (20/10/2026)

- Servidor PostgreSQL/PostGIS 16.9, base `siga`, esquema `siac`.
- Tres archivos TXT importados con carga recuperable y exclusiones históricas.
- **6.054.953 registros** publicados en `siac.vuelos_raw`.
- Vista `siac.vuelos`: conserva las 47 columnas de origen y añade conversiones.
- **66 relaciones** catalogadas desde Power BI: 50 activas y 16 inactivas. El catálogo documental no crea claves foráneas.
- Dimensiones creadas: `dim_aeropuerto_sna`, `dim_categoria_sna`, `dim_explotador_sna` (57 registros cada una) y `dim_fecha` (4.311 fechas en la primera carga).
- Se postergó la incorporación de LAD y `CodigosOACI_IATA_LAD.csv` por revisión de la base.

## Documentos

- [Historia técnica y decisiones](docs/HISTORIAL.md).
- [Procedimiento mensual obligatorio](docs/ACTUALIZACION_MENSUAL.md).
- [Controles SQL](sql/validaciones.sql).
- [Arquitectura, fuentes y pendientes](docs/MODELO.md).

## Principios

1. Preservar las **47 columnas** originales de SIAC.
2. No confundir `Pax`, `Pax_AD`, `Pasajeros`, `Pasajeros_AD`, `Movimientos` y `Vuelos`.
3. Reproducir las exclusiones de Power BI y eliminar registros anteriores a 2015.
4. Tratar `Tabla Final.txt` como **archivo reemplazable completo**: un mes puede corregir meses anteriores.
5. Validar antes de publicar. Nunca borrar la versión vigente al iniciar una carga.
6. No publicar IP internas, credenciales, datos originales ni rutas personales en GitHub.

## Próximas etapas

- Versionar los scripts exactos utilizados, previamente revisados y sin infraestructura privada.
- Incorporar dependencias y expresiones DAX convertidas a SQL.
- Validar varios años, aeropuertos y clasificaciones.
- Preparar la tabla mensual por aeropuerto con meses sin actividad y promedio móvil.
- Crear acceso de solo lectura para el futuro chatbot.

**Nota:** un repositorio GitHub no sustituye el respaldo de PostgreSQL. Resguardar base, scripts ejecutados y archivos fuentes en almacenamiento institucional autorizado.

## Control de versiones mensuales

- [Crear referencias y capturas anuales/mensuales](sql/03_control_versiones.sql).
- [Comparar antes y después de cada actualización](sql/04_comparar_versiones.sql).
- [Procedimiento paso a paso](docs/ACTUALIZACION_MENSUAL.md#h-control-de-versiones-y-diferencias-a-partir-de-octubre-2026).

**Pendiente de ejecutar en pgAdmin:** instalación del control y primera captura de línea base. Los scripts de GitHub no ejecutan SQL en el servidor.
