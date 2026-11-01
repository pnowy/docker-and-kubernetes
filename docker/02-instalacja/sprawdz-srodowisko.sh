#!/usr/bin/env bash
# Sekcja 2 – Sprawdzenie środowiska przed zajęciami (Docker Desktop lub Docker Engine na Ubuntu)
set -euo pipefail

docker version                       # wersja klienta (CLI) i serwera (daemon) – obie sekcje muszą się pojawić
docker info --format 'Kontekst: {{.Name}} | OS: {{.OperatingSystem}} | Architektura: {{.Architecture}} | CPU: {{.NCPU}} | RAM: {{.MemTotal}}'
docker compose version               # Compose v2 – plugin "docker compose", nie stary "docker-compose"
docker buildx version                # BuildKit / Buildx
docker context ls                    # z którym daemonem rozmawia CLI
docker run --rm hello-world          # pełna ścieżka: pull z Docker Hub → utworzenie kontenera → uruchomienie
