#!/usr/bin/env bash
# Sekcja 8 – Lab: notes-api w Pythonie + MariaDB w Compose (plik ../../app-python/compose.yaml)
cd "$(dirname "$0")/../../app-python" || exit 1

docker compose up -d --build
docker compose ps
sleep 5                                        # MariaDB startuje kilka sekund; aplikacja ponawia połączenie przy kolejnym żądaniu
curl -s http://localhost:8000/readyz; echo     # {"ready":true}
curl -s -X POST http://localhost:8000/notes -H 'Content-Type: application/json' -d '{"text":"Notatka z Compose"}'; echo
curl -s http://localhost:8000/notes; echo
docker compose logs api                        # najpierw "Baza niedostępna", potem "Połączono z bazą danych"
docker compose exec db mariadb -unotes -phaslo-szkoleniowe notes -e 'SELECT * FROM notes;'

# Trwałość: down bez -v zachowuje wolumin z danymi bazy
docker compose down
docker compose up -d
sleep 5
curl -s http://localhost:8000/notes; echo      # notatka nadal jest

# Baza zatrzymana – aplikacja działa, ale zgłasza brak bazy
docker compose stop db
curl -s http://localhost:8000/readyz; echo     # {"ready":false} – kod 503
docker compose start db

# Sprzątanie (z usunięciem danych): docker compose down -v
