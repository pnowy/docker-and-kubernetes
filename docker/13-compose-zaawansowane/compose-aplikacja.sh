#!/usr/bin/env bash
# Sekcja 13 – Aplikacja notes-api + PostgreSQL w Compose
cd "$(dirname "$0")/../../app-node" || exit 1

# --- Uruchomienie: .env, sekrety, healthcheck + depends_on ---
cat .env                                      # zmienne podstawiane w compose.yaml
docker compose config                         # wynik po podstawieniu zmiennych z .env
docker compose up -d --build --wait           # --wait: czekaj aż serwisy będą healthy
docker compose ps
curl -s http://localhost:8000/; echo
curl -s -X POST http://localhost:8000/notes -H 'Content-Type: application/json' -d '{"text":"Notatka z Compose"}'; echo
curl -s http://localhost:8000/notes; echo
docker compose exec db psql -U notes -d notes -c 'SELECT * FROM notes;'
docker compose exec api cat /run/secrets/db_password   # sekret zamontowany jako plik, nie zmienna środowiskowa

# --- Trwałość: down bez -v zachowuje wolumin z danymi bazy ---
docker compose down
docker compose up -d --wait
curl -s http://localhost:8000/notes; echo

# --- Nazwy serwisów są nazwami DNS w sieci projektu ---
docker compose run --rm --no-deps api node -e "require('dns').lookup('db', (e, a) => console.log('db →', a))"

# --- Profile: serwis adminer uruchamia się tylko z profilem "narzedzia" ---
docker compose --profile narzedzia up -d --wait
echo "Adminer: http://localhost:8081 (serwer: db, użytkownik: notes, hasło: secrets/db_password.txt)"
docker compose --profile narzedzia down

# --- Nadpisywanie plików i development z hot reload (compose watch) ---
docker compose -f compose.yaml -f compose.dev.yaml config | grep -A3 'target'
# docker compose -f compose.yaml -f compose.dev.yaml watch   # edytuj src/server.ts – zmiana trafia do kontenera (Ctrl+C)

# Sprzątanie (z usunięciem danych): docker compose down -v
