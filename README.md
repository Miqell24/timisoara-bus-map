# Timișoara Public Transport — interactive map

Interactive, poster-grade map of the public transport network of
**Timișoara**: STPT's city buses, the eight trolleybus lines and the six tram
lines, plus the metropolitan lines SMTT runs out to the surrounding communes —
56 lines drawn along the real street and track geometry.

## Live

Not published — this map is built and reviewed locally.

One feed covers everything, split by `route_type` at build time:

| mode | route_type | lines | graph |
|---|---|---|---|
| buses | 3 | 42 city, express (E) and metropolitan (M) lines | OSM roadways |
| trolleybuses | 11 | 11, 14, 15, 16, 17, 18, M11, M14 — drawn green on the bus network | OSM roadways |
| trams | 0 | 1, 2, 4, 7, 8, 9 | `railway=tram` tracks |

Timișoara has **no metro**, so the engine's metro treatment stays unused.

Build quirks worth knowing:

* **The V1 vaporetto is not drawn.** The feed carries one `route_type=4`
  line — the Bega canal boat — and a boat has neither roadway nor track to
  match against. Istanbul set the precedent when its ferries were built and
  then removed on request. V1 is simply absent from both cfgs in
  `pipeline/build.mjs`, which is what keeps it (and its stops) off the map.
* **Line numbers are unique across all three modes**, so the line keys are the
  bare numbers printed on the vehicles — none of the mode prefixes the Sofia
  sibling needs. Re-check on every feed refresh.
* **Stop names arrive properly cased and fully accented** ("Dâmbovița (Ion
  Barac)"), and Romanian is written in the Latin alphabet, so this map runs
  without the case dictionary and without the second, transliterated label
  line its Greek, Bulgarian and Serbian siblings carry.
* **A track row carries three colours here.** Trolleybuses 15 and 16 share the
  tracks of trams 1 and 9 along Bulevardul Liviu Rebreanu together with bus
  E2, so the row reads: tram numbers in the rail colour, then the numbers
  adopted from the roadway split again into trolleybus green and bus navy.
  The two-colour version of the sibling maps left 8 such rows flat.
* **The feed's own `route_color` is ignored**, as everywhere in this family:
  colour means the MODE. The service class stays legible in the number itself
  (E = express, M = metropolitan).
* **The metropolitan lines reach far past the city** — Cruceni in the south
  (45.47 N) and Seceani in the north (45.98 N) — so the OSM extract spans
  63 × 47 km.

## Pipeline

`npm run download` fetches the GTFS from SMTT, the OSM roadways, the tram
tracks and MapLibre GL. `npm run build` map-matches every line (HMM/Viterbi on
the OSM graphs) and writes GeoJSON to `data/out/`. `npm run serve` hosts the
map at http://localhost:8142.

Data: Societatea Metropolitană de Transport Timișoara (SMTT) / Societatea de
Transport Public Timișoara (STPT) · base map © OpenFreeMap / OpenMapTiles /
OpenStreetMap contributors.
