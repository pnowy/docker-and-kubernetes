#!/usr/bin/env bash
# Sekcja 10 – Multi-stage build aplikacji notes-api
set -euo pipefail
cd "$(dirname "$0")/../../app-node" || exit 1

# Wersja 1: jeden etap, pełny obraz node:24 – kompilator TS i zależności dev trafiają do obrazu
docker build -t notes-api:simple -f Dockerfile.simple .

# Wersja 2: multi-stage – do obrazu końcowego trafia tylko dist/ i zależności produkcyjne
docker build -t notes-api:1.0.0 .
docker image ls notes-api --format 'table {{.Tag}}\t{{.Size}}'

# Budowanie wybranego etapu (np. do debugowania albo developmentu)
docker build --target build -t notes-api:build .
docker run --rm notes-api:build ls node_modules/.bin          # tsc jest tylko w etapie build
docker run --rm notes-api:1.0.0 ls node_modules/.bin 2>&1 || echo "runtime: brak narzędzi deweloperskich"
docker run --rm notes-api:1.0.0 whoami                        # node – nie root
docker rmi notes-api:build
