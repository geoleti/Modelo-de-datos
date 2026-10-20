# Incorporación de DimCodigos_Lookup y RutaCompleta

- Origen: 10.084 equivalencias OACI/IATA exportadas de Power BI.
- [SQL de dimensión y vista](../sql/07_dim_codigos_y_rutas.sql).
- RutaCompleta reproduce el orden alfabético de Power Query y completa códigos faltantes con la dimensión.
- El dato original de 10.084 filas se conserva por separado: no está incorporado al repositorio público.

## Pasos

1. Descargar del chat `08_cargar_10084_codigos.sql` y `ejecutar_sql_siac.py`.
2. Colocar el ejecutor junto a la configuración local `config_siac.local.json`.
3. Ejecutar con PowerShell `py -3 ejecutar_sql_siac.py "RUTA_COMPLETA_DE_08_cargar_10084_codigos.sql"`.
4. Comprobar 10.084 códigos cargados.
5. Abrir [sql/07_dim_codigos_y_rutas.sql](../sql/07_dim_codigos_y_rutas.sql), copiar y pegar en pgAdmin Query Tool. Ejecutar.
6. Comprobar rutas con `SELECT "OrigenCompleto", "DestinoCompleto", "RutaCompleta" FROM siac.vuelos_rutas LIMIT 15;`.

La dimensión usa una clave única en `icao_code`: la unión no multiplica las filas. La vista parte de `siac.vuelos_validos`, con el período de corte confirmado. No modifica las 47 columnas de origen.

**Nota:** la normalización convierte los códigos a mayúsculas y trata `NA` y `N/A` como faltantes. Revisar los valores no estándar antes de usar rutas en informes oficiales.
