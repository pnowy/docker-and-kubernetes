#!/usr/bin/env bash
# Sekcja 14 – Wersjonowanie i aktualizacje obrazów
cd "$(dirname "$0")/../../app-node" || exit 1

# Jeden build, kilka tagów: pełna wersja (niezmienna), ruchome 1.2 i 1, SHA commita (identyfikacja źródła)
WERSJA=1.2.0
SHA=$(git rev-parse --short HEAD 2>/dev/null || echo lokalny)
docker build -q \
  --label org.opencontainers.image.version="$WERSJA" \
  --label org.opencontainers.image.revision="$SHA" \
  --label org.opencontainers.image.created="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -t notes-api:"$WERSJA" -t notes-api:1.2 -t notes-api:1 -t notes-api:sha-"$SHA" .
docker images notes-api --format 'table {{.Tag}}\t{{.ID}}'   # wszystkie tagi → ten sam ID obrazu
docker inspect --format '{{json .Config.Labels}}' notes-api:"$WERSJA"

# Wdrażamy po pełnej wersji albo po digeście – nigdy po latest
docker inspect --format '{{index .RepoDigests 0}}' postgres:18   # digest obrazu bazowego

# Aktualizacje: obraz bazowy (np. node:24-slim) dostaje poprawki bezpieczeństwa pod tym samym tagiem.
# --pull pobiera świeży obraz bazowy, --no-cache wymusza ponowne wykonanie instrukcji (np. apt-get upgrade)
docker build -q --pull -t notes-api:"$WERSJA" .
# Co zmieniło się w obrazie bazowym i czy są nowsze wersje – Docker Scout:
# docker scout recommendations notes-api:1.2.0
# Automatyczne PR-y z aktualizacją FROM i digestów: Dependabot (ekosystem "docker") lub Renovate.

# Sprzątanie
docker rmi notes-api:1.2.0 notes-api:1.2 notes-api:1 notes-api:sha-"$SHA"
