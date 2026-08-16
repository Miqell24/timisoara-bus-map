#!/usr/bin/env bash
# Downloads input data: Timișoara GTFS (SMTT), OSM networks (Overpass),
# MapLibre GL. Everything is cached — re-running only fetches what is missing.
#
# ONE feed covers the whole network: STPT's city buses, trolleybuses and trams
# plus the metropolitan lines SMTT runs out to the surrounding communes, split
# by route_type at build time. There is no metro in Timișoara.
#
# The feed also carries ONE route_type=4 line — V1, the Bega vaporetto. It is
# not drawn: a boat has no roadway and no track to match against, and the
# family's precedent is Istanbul, where the ferries were built and then removed
# on request. Its stops stay out of the map with it.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs data/osm web/vendor

# The metropolitan lines reach far past the city: Cruceni in the south
# (45.47 N) and Seceani/Bărăteaz in the north (45.98 N). Stops span
# 45.472–45.977 N / 20.861–21.421 E.
BB_S=45.44; BB_W=20.82; BB_N=46.01; BB_E=21.46

# 1) GTFS — SMTT's own publication (stable path, refreshed in place; the same
#    file the Mobility Database serves as mdb-2868)
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== SMTT GTFS (Timișoara) =="
  curl -fL --retry 3 --max-time 600 -o data/timisoara-gtfs.zip \
    "https://smtt.ro/transit/gtfs/maps/smtt-timisoara-ro.zip"
  unzip -o data/timisoara-gtfs.zip -d data/gtfs
fi

# 2) OSM — roadways. The bbox is 63 × 47 km but thinly built outside the city,
#    so a single query still fits; the mirrors rotate if it does not.
if [ ! -f data/osm/timisoara.json ]; then
  echo "== Overpass (roads) =="
  QR="[out:json][timeout:900];way($BB_S,$BB_W,$BB_N,$BB_E)[\"highway\"~\"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|service|busway|construction|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)$\"];out geom;"
  ok=0
  # overpass-api.de first: the lighter mirrors have been caught serving a stale
  # database (Naples, 16.08.2026 — a line opened in 2025 was missing)
  for EP in "https://overpass-api.de/api/interpreter" \
            "https://maps.mail.ru/osm/tools/overpass/api/interpreter" \
            "https://overpass.kumi.systems/api/interpreter"; do
    echo "-- $EP"
    if curl -fsS --max-time 900 -o data/osm/timisoara.json --data-urlencode "data=$QR" "$EP" \
       && grep -q '"elements"' data/osm/timisoara.json; then
      ok=1; break
    fi
    sleep 5
  done
  [ "$ok" = 1 ] || { echo "Overpass (roads): all mirrors failed" >&2; exit 1; }
fi

# 2b) OSM — tram tracks for the rail mode. `disused` and `construction` come
#     along on purpose: OSM lags behind reopenings, and Timișoara has been
#     rebuilding tram corridors line by line for years (Belgrade, 16.08.2026:
#     a whole four-line corridor sat under disused:railway=tram with an
#     opening_date already past). See railKind() in pipeline/lib/graph.mjs.
if [ ! -f data/osm/timisoara-rail.json ]; then
  echo "== Overpass (tram tracks) =="
  QT="[out:json][timeout:300];way($BB_S,$BB_W,$BB_N,$BB_E)[\"railway\"~\"^(tram|construction|disused)$\"];out geom;"
  ok=0
  for EP in "https://overpass-api.de/api/interpreter" \
            "https://maps.mail.ru/osm/tools/overpass/api/interpreter" \
            "https://overpass.kumi.systems/api/interpreter"; do
    echo "-- $EP"
    if curl -fsS --max-time 300 -o data/osm/timisoara-rail.json --data-urlencode "data=$QT" "$EP" \
       && grep -q '"elements"' data/osm/timisoara-rail.json; then
      ok=1; break
    fi
    sleep 5
  done
  [ "$ok" = 1 ] || { echo "Overpass (rails): all mirrors failed" >&2; exit 1; }
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/timisoara-gtfs.zip data/osm/timisoara.json data/osm/timisoara-rail.json 2>/dev/null || true
