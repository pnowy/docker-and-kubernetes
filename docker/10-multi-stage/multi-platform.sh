#!/usr/bin/env bash
# Sekcja 10 – Obrazy wieloplatformowe (amd64 + arm64), np. Mac z Apple Silicon → serwer x86_64
cd "$(dirname "$0")/../../app-node" || exit 1

docker buildx imagetools inspect node:24-slim | grep Platform   # obraz bazowy ma warianty dla wielu architektur
docker info -f '{{.Architecture}}'                              # architektura Twojego daemona

# Obraz dla innej architektury niż Twoja (budowanie przez emulację QEMU – wolniej)
docker build --platform linux/amd64 -t notes-api:amd64 .
docker image inspect -f '{{.Os}}/{{.Architecture}}' notes-api:amd64
docker run --rm --platform linux/amd64 notes-api:amd64 node -p process.arch   # x64 – działa w emulacji

# Jeden tag dla obu architektur wymaga containerd image store
# (Docker Desktop: Settings → General → "Use containerd for pulling and storing images" – domyślnie w nowych instalacjach)
# lub buildera docker-container: docker buildx create --name multi --use
docker buildx build --platform linux/amd64,linux/arm64 -t notes-api:multi . \
  || echo "Włącz containerd image store, aby budować obrazy wieloplatformowe lokalnie"
# Do rejestru: docker buildx build --platform linux/amd64,linux/arm64 -t <rejestr>/notes-api:1.0.0 --push .
docker rmi notes-api:amd64
