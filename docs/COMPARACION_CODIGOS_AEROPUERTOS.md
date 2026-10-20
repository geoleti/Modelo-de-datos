# Comparación de códigos OACI/IATA — 20/10/2026

Fuentes:
- DimCodigos_Lookup: tabla exportada de Power BI, proporcionada como texto tabulado (10.084 filas).
- [geodata/fuentes/ourairports.csv](https://github.com/udseyt-greyf/geodata/blob/main/fuentes/ourairports.csv): formato `iata;oaci;continent;latitude;longitude;municipality;country` (9.208 filas).

## Método
Se normalizaron espacios y mayúsculas; se compararon los registros por código OACI no vacío. Se contrastó el código IATA asociado.

| Control | Total |
|---|---:|
| DimCodigos_Lookup, filas y códigos OACI únicos | 10.084 |
| ourairports.csv, filas | 9.208 |
| ourairports.csv, OACI no vacíos únicos | 8.225 |
| Mismo OACI e IATA | 8.208 |
| Mismo OACI y distinto IATA | 0 |
| Solo en DimCodigos_Lookup | 1.876 |
| Solo en ourairports.csv | 17 |
| DimCodigos_Lookup sin IATA | 2.399 |
| DimCodigos_Lookup con OACI numérico | 886 |
| Solo en DimCodigos_Lookup con IATA | 618 |
| Solo en DimCodigos_Lookup sin IATA | 1.258 |
| ourairports.csv sin OACI | 983 |

Códigos solo en ourairports.csv: `SAAJ`, `SBSG`, `HEBA`, `SNOS`, `SA03`, `SA01`, `SADZ`, `SAAN`, `SATO`, `SARV`, `SAAA`, `SA02`, `SAOM`, `SAVO`, `SA32`, `SACD`, `SAZE:SA`.

**Alerta:** `SAZE:SA` no tiene un formato OACI normal y requiere revisión de origen.

## Decisión
Conservar DimCodigos_Lookup como referencia principal para reproducir `RutaCompleta` en SIAC; usar ourairports.csv para enriquecer con país, continente y coordenadas. No reemplazar ni fusionar sin verificar códigos y cardinalidad. No se ejecutaron cambios en PostgreSQL.

**Nota:** comparación entre estas dos versiones de archivos; no equivale a una auditoría frente al catálogo oficial OACI/IATA.
