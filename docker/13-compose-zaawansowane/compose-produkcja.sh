#!/usr/bin/env bash
# Sekcja 13 – Compose na serwerze: nadpisanie compose.prod.yaml (obraz z rejestru, limity, logi, izolacja sieci)
cd "$(dirname "$0")/../../app-node" || exit 1

# Na serwerze obraz pochodzi z rejestru (docker compose pull – sekcja 14). Tu nadajemy lokalnemu obrazowi tę samą nazwę:
docker build -t notes-api:1.0.0 .
docker tag notes-api:1.0.0 localhost:5000/notes-api:1.0.0
docker compose -f compose.yaml -f compose.prod.yaml config --quiet && echo "plik poprawny"
docker compose -f compose.yaml -f compose.prod.yaml config | grep -E 'build|image:|host_ip|internal|max-size'
# docker compose -f compose.yaml -f compose.prod.yaml pull api      # na serwerze: pobranie obrazu z rejestru
docker compose -f compose.yaml -f compose.prod.yaml up -d --wait

curl -s 127.0.0.1:8000/readyz; echo                                   # port tylko na localhost
docker inspect notes-api-1 --format '{{.HostConfig.LogConfig}} mem={{.HostConfig.Memory}} cpu={{.HostConfig.NanoCpus}}'
docker compose -f compose.yaml -f compose.prod.yaml exec api touch /app/x   # Read-only file system
docker compose -f compose.yaml -f compose.prod.yaml exec db getent hosts deb.debian.org || echo "db: brak dostępu do internetu (sieć internal)"

# Aktualizacja wersji: nowy tag w .env / zmiennej, pull i up – Compose odtwarza tylko zmienione serwisy
# APP_VERSION=1.0.1 docker compose -f compose.yaml -f compose.prod.yaml pull && … up -d --wait

docker compose -f compose.yaml -f compose.prod.yaml down
