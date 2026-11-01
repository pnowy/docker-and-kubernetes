#!/usr/bin/env bash
# Sekcja 12 – Kolejność instrukcji i cache buildera
set -euo pipefail
cd "$(dirname "$0")/../../app-node" || exit 1

# Zbuduj obie wersje raz, żeby cache był "ciepły"
docker build -q -t notes-api:simple -f Dockerfile.simple . > /dev/null
docker build -q -t notes-api:cached -f Dockerfile.cached . > /dev/null

# Zmiana w kodzie aplikacji (nie w zależnościach)
cp src/server.ts /tmp/server.ts.bak
echo "// zmiana $(date +%s)" >> src/server.ts

# Dockerfile.simple: COPY . . przed npm ci → każda zmiana kodu unieważnia cache i npm ci wykonuje się od nowa
time docker build --progress=plain -t notes-api:simple -f Dockerfile.simple . 2>&1 | grep -E 'npm ci|CACHED|DONE' | head -8

# Dockerfile.cached: te same instrukcje, ale najpierw package*.json i npm ci, potem src/ → npm ci pochodzi z cache (CACHED)
time docker build --progress=plain -t notes-api:cached -f Dockerfile.cached . 2>&1 | grep -E 'npm ci|CACHED|DONE' | head -12

mv /tmp/server.ts.bak src/server.ts

# --- Narzędzia diagnostyczne ---
docker history notes-api:cached                               # rozmiar każdej warstwy
docker system df                                              # obrazy, kontenery, woluminy, cache buildera
docker buildx du | tail -3                                    # rozmiar cache BuildKit
# dive notes-api:cached                                       # interaktywny eksplorator warstw (brew install dive)
