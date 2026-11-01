#!/usr/bin/env bash
# Sekcja 10 (dodatkowo) – Multi-stage build aplikacji notes-api w Pythonie (app-python)
set -euo pipefail
cd "$(dirname "$0")/../../app-python" || exit 1

# Wersja 1: jeden etap, pełny obraz python:3.12 – kompilatory i nagłówki zostają w obrazie
docker build -t notes-api-python:simple -f Dockerfile.simple .

# Wersja 2: multi-stage – builder instaluje zależności do /install, runtime kopiuje je do /usr/local razem z kodem
docker build -t notes-api-python:1.0.0 .
docker image ls notes-api-python --format 'table {{.Tag}}\t{{.Size}}'   # ok. 1,2 GB vs 170 MB

docker run --rm notes-api-python:1.0.0 whoami                          # app – nie root
docker run -d --name notes-py -p 8000:8000 -e STORAGE=json notes-api-python:1.0.0
sleep 3
curl http://localhost:8000/                                             # "storage":"json"
docker ps --filter name=notes-py                                        # (healthy) po ok. 10 s

# Sprzątanie: docker rm -f notes-py
