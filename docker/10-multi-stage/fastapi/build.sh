#!/usr/bin/env bash
# Sekcja 10 – Multi-stage build aplikacji Python/FastAPI (przykład z materiałów ALX)
set -euo pipefail
cd "$(dirname "$0")" || exit 1

docker build -t moja-api:latest .
docker images moja-api                       # ok. 170 MB – w obrazie tylko zależności i kod
docker build -t moja-api:builder --target builder .
docker images moja-api                       # etap builder – z pip i plikami instalacyjnymi
docker run -d --name moja-api -p 8000:8000 moja-api:latest
sleep 2
curl http://localhost:8000/                  # {"message":"Hello ALX","version":"dev"}
docker exec moja-api whoami                  # nobody

# Sprzątanie: docker rm -f moja-api && docker rmi moja-api:builder
