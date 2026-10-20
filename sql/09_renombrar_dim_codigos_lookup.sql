-- Cambio de nombre de la dimensión existente, sin modificar registros.
-- El contenido procede de DimCodigos_Lookup de Power BI (10.084 equivalencias).
-- NO corresponde al CSV geográfico ourairports.csv.
BEGIN;
ALTER TABLE siac.dim_codigos_lookup RENAME TO ourairport;
COMMIT;

-- PostgreSQL actualiza automáticamente las dependencias internas de las vistas.
-- Revisar por separado los scripts guardados que referencian el nombre anterior.
