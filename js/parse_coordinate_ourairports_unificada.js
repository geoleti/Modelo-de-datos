// Conversor unificado para geodata/fuentes/ourairports.csv.
// No reemplaza automáticamente las funciones existentes de geodata.
// Retorna NaN cuando no existe conversión defendible.
// Conserva el dato original fuera de esta función.
function parseCoordinateUnificada(value, type = "lat", context = {}) {
  if (value == null) return NaN;
  const raw = String(value).trim()
    .replace(/^['"]+|['"]+$/g, "")
    .replace(/\s+/g, "")
    .replace(/,/g, ".");
  if (!raw) return NaN;
  if (!/^-?\d+(?:\.\d+)*$/.test(raw)) return NaN;

  const max = type === "lon" ? 180 : 90;
  const country = String(context.countryCode || "").toUpperCase();
  const continent = String(context.continent || "").toUpperCase();
  const countryBounds = {
    AR: {lat:[-56,-21],lon:[-74,-52]}, UY:{lat:[-36,-30],lon:[-59,-53]},
    PY:{lat:[-28,-19],lon:[-63,-54]}, BR:{lat:[-35,6],lon:[-75,-32]},
    CL:{lat:[-56,-17],lon:[-76,-66]}, PE:{lat:[-19,1],lon:[-82,-68]},
    BO:{lat:[-23,-9],lon:[-70,-57]}, CO:{lat:[-5,14],lon:[-82,-66]},
    EC:{lat:[-6,2],lon:[-82,-75]}, VE:{lat:[0,13],lon:[-74,-59]},
    US:{lat:[18,72],lon:[-170,-60]}, MX:{lat:[14,33],lon:[-119,-86]},
    PA:{lat:[7,10],lon:[-83,-77]}, DO:{lat:[17,20],lon:[-73,-68]},
    CU:{lat:[19,24],lon:[-86,-74]}, ES:{lat:[35,44.5],lon:[-10,5]},
    IT:{lat:[35,48],lon:[6,19.5]}, FR:{lat:[41,52],lon:[-6,10]},
    NL:{lat:[50,54],lon:[3,8]}, DE:{lat:[47,56],lon:[5,16]},
    GB:{lat:[49,61],lon:[-9,2]}, PT:{lat:[36,43],lon:[-10,-6]}
  };
  const continentBounds = {
    SA:{lat:[-60,15],lon:[-90,-30]}, NA:{lat:[5,85],lon:[-170,-50]},
    EU:{lat:[34,72],lon:[-25,60]}, AF:{lat:[-40,38],lon:[-20,55]},
    AS:{lat:[-10,80],lon:[25,180]}, OC:{lat:[-50,10],lon:[110,180]},
    AN:{lat:[-90,-60],lon:[-180,180]}
  };
  const bounds = countryBounds[country] || continentBounds[continent];
  const preferred = bounds?.[type] || null;
  const valid = n => Number.isFinite(n) && Math.abs(n) <= max;
  const inRegion = n => preferred && valid(n) &&
    n >= preferred[0] && n <= preferred[1];

  // 1. Conversión directa para valores bien formados.
  const direct = Number(raw);
  if (valid(direct) && (!preferred || inRegion(direct))) return direct;

  // 2. Método del segundo conversor: conservar primer punto,
  // juntar segmentos restantes.
  const sign = raw.startsWith("-") ? -1 : 1;
  const unsigned = raw.replace(/^-/, "");
  const segments = unsigned.split(".");
  const joined = segments.length > 1
    ? sign * Number(segments[0] + "." + segments.slice(1).join(""))
    : sign * Number(unsigned);
  if (inRegion(joined)) return joined;

  // 3. Método del primer conversor: desplazar el separador decimal,
  // priorizando valores dentro del país o continente.
  const digits = unsigned.replace(/\./g, "");
  const base = Number(digits);
  const candidates = [];
  if (Number.isFinite(base)) {
    for (let decimals = 0; decimals <= Math.min(digits.length, 16); decimals++) {
      const n = sign * base / (10 ** decimals);
      if (valid(n) && !candidates.some(x => x === n)) candidates.push(n);
    }
  }
  // Si el valor no está bien formado, nunca aceptar un desplazamiento
  // basado solo en límites globales sin información geográfica.
  if (preferred) {
    const match = candidates.find(inRegion);
    if (match !== undefined) return match;
  }
  // 4. Respaldo del segundo conversor: solo conversión simple global.
  if (valid(joined) && !preferred) return joined;
  return NaN;
}
