# Actualización mensual de Tabla Final.txt

**Documento operativo – 20/10/2026.** Este procedimiento describe la operación manual verificada. Todavía no existe una tarea programada.

## Regla esencial

El proveedor **reemplaza íntegramente** `Tabla Final.txt` cada mes. Además de vuelos nuevos, puede contener modificaciones retroactivas. **No agregar solamente las filas nuevas.** Sustituir la versión completa de ese archivo después de verificar la nueva carga.

Los otros dos archivos son históricos: `Tabla Final_hasta_2019.txt` y `Tabla Final (con encabezados).txt`. El importador comprueba su huella SHA-256 y omite los archivos sin cambios.

## Reglas de exclusión (iguales a Power BI)

| Archivo | Regla |
|---|---|
| Todos | Excluir `Año_Local < 2015` |
| `Tabla Final_hasta_2019.txt` | Excluir año 2019 |
| `Tabla Final (con encabezados).txt` | Excluir 2023, 2024 y 2025 |
| `Tabla Final.txt` | Sin exclusiones adicionales por archivo |

Si aparecen TXT nuevos, **detenerse y definir su prioridad y solapamientos** antes de modificar el importador. La versión documentada solo procesa esos tres nombres.

## Preparación

1. Confirmar que la copia mensual del TXT terminó de escribirse en la carpeta de red.
2. Verificar acceso VPN/red, estabilidad de la unidad compartida y suficiente espacio en el servidor.
3. Conservar una copia segura de la versión previa cuando la política institucional lo permita.
4. Confirmar que la importación anterior figura como `completado` en `siac.archivos_importados`.
5. Guardar un respaldo de PostgreSQL antes de cambios importantes.
6. Ejecutar una sola instancia del importador; no ejecutar otras cargas simultáneas.

## Ejecución desde Windows

Abrir PowerShell en la carpeta donde está `importar_siac_recuperable.py`:

```powershell
py -3 importar_siac_recuperable.py
```

Escribir la contraseña en la consola cuando se solicite. **Nunca guardarla en el repositorio.**

El programa histórico utilizado implementa:
- Lectura `cp1252`, delimitador `;`, comillas dobles y 47 columnas.
- Huella SHA-256 para identificar cambios.
- Procesamiento en lotes de 50.000 filas.
- Tabla de preparación `siac.vuelos_carga` y seguimiento en `siac.archivos_importados`.
- Publicación por archivo en una transacción: elimina filas correspondientes a la versión previa y publica la nueva solo cuando la carga está validada.

**Importante:** los bloques de preparación se confirman; la publicación final sigue siendo una transacción pesada. No cerrar PowerShell mientras esa publicación funciona.

## Qué mensajes esperar

- `Sin cambios. Se conserva versión publicada.`: huella idéntica; no reprocesa.
- `Carga N. Reanudar desde fila X.`: recupera una carga incompleta.
- `... cargados en preparación`: avance; aún **no publicados**.
- `PUBLICADO: Tabla Final.txt: N filas válidas.`: sustitución finalizada.
- `Todos los archivos procesados.`: terminó el recorrido.

## Verificación obligatoria en pgAdmin

Ejecutar `sql/validaciones.sql`. Confirmar:
- Las tres versiones publicadas tienen estado `completado`.
- Las cantidades por archivo corresponden al TXT nuevo.
- El rango de años comienza en 2015.
- No existen versiones de un mismo archivo simultáneamente publicadas.
- Los totales oficiales comparables con Power BI coinciden.
- No hay cargas `procesando` sin explicación.

## Si falla

1. **No borrar** `vuelos_raw`, `vuelos_carga` ni `archivos_importados`.
2. Guardar el mensaje completo y revisar registros de PostgreSQL.
3. Confirmar que la versión anterior permanece `completado`.
4. Si el TXT sigue idéntico, ejecutar de nuevo el importador: puede reanudar.
5. Si el TXT cambió, investigar el estado del intento pendiente antes de reintentar.
6. Si la publicación está ejecutándose, **no iniciar una segunda instancia**.

El error inicial de 19/10/2026 fue `Connection reset by peer` durante un `COPY` monolítico. La solución aplicada fue la importación recuperable.

## Actualización de productos derivados

La vista `siac.vuelos` lee `vuelos_raw` y refleja los datos publicados.

Las **vistas materializadas no se actualizan solas**. Si se crea `siac.pasajeros_mensuales`, efectuar el `REFRESH MATERIALIZED VIEW` después de la publicación y validación. Ejecutarlo solo cuando esté desplegada y probada. Las dimensiones de fecha también deben extenderse a nuevas fechas.

## Seguridad

El repositorio es público: no subir TXT, archivos de datos internos, claves, respaldos, nombres de usuario/host internos ni direcciones de red. Ejecutar las cargas en la red autorizada.
