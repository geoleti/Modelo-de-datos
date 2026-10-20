# Feriados Argentina 2000–2028: diagnóstico y corrección Power Query

## Fuente y dependencia

Consulta `Feriados Argentina 2000 2028`:
```powerquery
let
    Origen = Table_GenerateHoliDays("Argentina", 2000, 2028),
    #"Valor reemplazado" = Table.ReplaceValue(Origen,"Domingo de Resurrección","Domingo de Pascuas",Replacer.ReplaceText,{"Descripción"}),
    #"Valor reemplazado1" = Table.ReplaceValue(#"Valor reemplazado","Fiesta de Fin de Año","Fin de Año",Replacer.ReplaceText,{"Descripción"}),
    #"Columnas con nombre cambiado" = Table.RenameColumns(#"Valor reemplazado1",{{"Descripción", "Feriado"}})
in
    #"Columnas con nombre cambiado"
```

La función `Table_GenerateHoliDays` procede del código atribuido por la usuaria a Miguel Caballero y Fabian Torres (ExcelFreeBlog). Extrae elementos `ClassName = "hdays"` de `https://www.cuandoenelmundo.com/calendario/argentina/<año>` mediante `Web.Page(Web.Contents(...))`. El rango solicitado es 2000–2028.

## Error observado (20/10/2026)

`Expression.Error: No había suficientes elementos en la enumeración para completar la operación. Detalles: [List]`

En `FnDiasFestivos`:
```powerquery
SeleccionarDatos = SeleccionarFestivos[Data],
CombinarFilasFestivas = Table.Combine({ SeleccionarDatos{0}, SeleccionarDatos{1} }),
```

La función supone que hay dos tablas con clase `hdays` para cada año. Si se devuelven cero o una, el acceso por índice falla. También puede fallar si cambia el HTML del sitio.

## Corrección propuesta

Reemplazar **solo** `CombinarFilasFestivas` por:
```powerquery
CombinarFilasFestivas =
    if List.IsEmpty(SeleccionarDatos) then
        #table({"Column1", "Column2", "Column3"}, {})
    else
        Table.Combine(SeleccionarDatos),
```

Esta modificación evita índices fuera de rango y conserva todas las tablas efectivamente encontradas. **Pendiente de validación por la usuaria en Power BI**.

## Advertencia de calidad de datos

Eliminar el error no demuestra que los datos estén completos o actualizados. El sitio puede cambiar su estructura o dejar años sin tablas, y la función devolverá una tabla vacía en esos casos. Verificar cantidad de feriados por año y validez de las fechas antes de utilizar la dimensión. Si la fuente deja de ser fiable, evaluar un origen oficial o mantenido.

## Resultado tras aplicar la corrección (20/10/2026)

La usuaria comprobó que la consulta ya no muestra el error de enumeración, **pero las columnas `Fecha` y `Feriado` muestran únicamente valores `null` en la vista previa**. Por tanto, la corrección anterior **no recuperó feriados utilizables**. No dar la función por reparada ni cargar estos datos a SIAC.

Se identificó una API alternativa documentada: https://argentinadatos.com/docs/operations/get-feriados ; su rango declarado es **2016–2026**. No reemplaza automáticamente el requerimiento histórico completo **2000–2028**. La página oficial https://www.argentina.gob.ar/feriados permite contrastar fechas publicadas, pero tampoco se ha confirmado una API histórica para todo el rango.

**Próxima decisión:** revisar una fuente para el rango histórico completo o particionar histórico y futuro sin inventar fechas. Registrar cobertura y procedencia por año.
