# DimCodigos_Lookup y RutaCompleta

## Carga confirmada: 20/10/2026

Se cargaron **10.084 equivalencias OACI/IATA** en la base `siga`, esquema `siac`, mediante el ejecutor Python.

Salida confirmada en PowerShell:

```text
SQL: 08_cargar_10084_codigos.sql; base: siga
Contraseña de PostgreSQL:
SQL ejecutado correctamente.
```

**ATENCIÓN: los tres archivos deben estar en la MISMA carpeta del equipo Windows:**

```text
C:\Users\<usuario>\SIAC\
├── ejecutar_sql_siac.py
├── 08_cargar_10084_codigos.sql
└── config_siac.local.json
```

- `ejecutar_sql_siac.py`: ejecuta el archivo SQL.
- `08_cargar_10084_codigos.sql`: contiene 10.084 equivalencias OACI/IATA.
- `config_siac.local.json`: contiene los parámetros de conexión. **No publicar contraseñas ni este archivo.**

**Abrir PowerShell desde esa carpeta** y ejecutar exactamente:

```powershell
cd "$HOME\SIAC"
py -3 .\ejecutar_sql_siac.py .\08_cargar_10084_codigos.sql
```

No utilizar una ruta en `Downloads` cuando el archivo SQL está en `SIAC`. Las rutas relativas `.\` dependen de la carpeta actual de PowerShell.

## Modelo

- La dimensión `siac.dim_codigos_lookup` usa `icao_code` como clave primaria.
- La vista `siac.vuelos_rutas` calcula `OrigenCompleto`, `DestinoCompleto` y `RutaCompleta`.
- La vista toma registros de `siac.vuelos_validos`; no altera vuelos originales.
- Código de la vista: [sql/07_dim_codigos_y_rutas.sql](../sql/07_dim_codigos_y_rutas.sql).

**Estado:** la carga SQL está confirmada. La creación de `siac.vuelos_rutas` en pgAdmin requiere ejecutarse por separado.

## Crear la vista en pgAdmin

1. Abrir [sql/07_dim_codigos_y_rutas.sql](../sql/07_dim_codigos_y_rutas.sql).
2. Copiar el SQL.
3. Pegar en pgAdmin Query Tool, conectado a `siga`.
4. Ejecutar con F5.

La creación de la tabla usa `IF NOT EXISTS`. No elimina los códigos cargados.

Comprobación opcional:

```sql
SELECT COUNT(*) AS codigos FROM siac.dim_codigos_lookup;
SELECT "OrigenCompleto", "DestinoCompleto", "RutaCompleta"
FROM siac.vuelos_rutas LIMIT 15;
```

## Fuente

- DimCodigos_Lookup: tabla Power BI aportada por la usuaria, 10.084 equivalencias.
- [Comparación contra ourairports.csv](COMPARACION_CODIGOS_AEROPUERTOS.md).
- No subir `config_siac.local.json` a un repositorio público.
