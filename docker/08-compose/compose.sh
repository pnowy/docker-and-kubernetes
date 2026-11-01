#!/usr/bin/env bash
# Sekcja 8 – Podstawowe polecenia Docker Compose (Apache + MariaDB, uruchamiaj w tym katalogu)
cd "$(dirname "$0")" || exit 1

docker compose up -d          # Uruchom wszystkie serwisy w tle (obraz web zbuduje się przy pierwszym uruchomieniu)
docker compose ps             # Status serwisów
curl -s http://localhost:8080/
docker compose logs web       # Logi serwisu 'web' (-f = na żywo)
docker compose exec web ls /var/www/html               # polecenie w serwisie (interaktywnie: docker compose exec web bash)
sleep 10                      # MariaDB potrzebuje chwili na start – depends_on czeka tylko na uruchomienie kontenera
docker compose exec db mariadb -uroot -psekret -e "SHOW DATABASES;"
docker compose build          # Zbuduj obrazy
docker compose restart        # Restart serwisów
docker compose down           # Zatrzymaj i usuń kontenery
# docker compose down -v      # Dodatkowo usuń woluminy
