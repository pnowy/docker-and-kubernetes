#!/usr/bin/env bash
# Sekcja 13 – Docker Compose: .env, healthcheck, nadpisywanie konfiguracji (przykład z materiałów ALX)
cd "$(dirname "$0")" || exit 1

docker compose config                 # podgląd konfiguracji z podstawionymi zmiennymi z .env
docker compose up -d --build          # app wystartuje dopiero, gdy db będzie "healthy"
docker compose ps
sleep 3
curl http://localhost:8000/           # {"message":"Hello ALX","version":"2.1.0"}
docker compose down

# Nadpisywanie dla środowisk (dev vs prod) przez scalanie plików
docker compose -f docker-compose.yml -f docker-compose.prod.yml config
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d   # port 80 – na Linuksie może wymagać uprawnień
sleep 3
curl http://localhost:80/              # zajęty port 80? zmień w docker-compose.prod.yml na np. "8090:8000"
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
