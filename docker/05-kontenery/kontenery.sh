#!/usr/bin/env bash
# Sekcja 5 – Zarządzanie kontenerami. Wymaga obrazu moj-apache:1.0 (../04-dockerfile/build.sh).
# Wykonuj polecenia pojedynczo i obserwuj wynik.

# --- Uruchamianie kontenerów ---
# Uruchomienie kontenera Apache
docker run -d --name moj-serwer-www -p 8080:80 moj-apache:1.0

# Kontener interaktywny (wyjście: exit)
# docker run -it --rm ubuntu:20.04 /bin/bash

# Z limitem zasobów (w materiałach obraz moja-api:latest – nie istnieje, używamy moj-apache:1.0)
docker run -d --memory=512m --cpus=1.0 --name api-server moj-apache:1.0

# Ze zmienną środowiskową (-e)
docker run --rm -e IMIE=Ala ubuntu:20.04 sh -c 'echo "Cześć $IMIE"'

# --- Listowanie działających kontenerów ---
docker ps
docker ps -a     # Wszystkie, w tym zatrzymane
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# --- Zarządzanie stanem kontenera ---
docker stop moj-serwer-www      # Graceful stop (SIGTERM)
docker start moj-serwer-www
docker restart moj-serwer-www
docker pause moj-serwer-www     # Wstrzymanie procesów
docker unpause moj-serwer-www
# docker kill moj-serwer-www    # Natychmiastowe zatrzymanie (SIGKILL)

# --- Wyświetlanie logów ---
docker logs moj-serwer-www
docker logs --tail=50 moj-serwer-www   # Ostatnie 50 linii
# docker logs -f moj-serwer-www        # Śledzenie na żywo (Ctrl+C)

# --- Wykonywanie poleceń w działającym kontenerze ---
docker exec moj-serwer-www ls /var/www/html
# docker exec -it moj-serwer-www /bin/bash

# --- Kopiowanie plików między hostem a kontenerem ---
curl -s http://localhost:8080/ > /dev/null                  # jedno żądanie, żeby log nie był pusty
docker cp moj-serwer-www:/var/log/apache2/access.log .     # Z kontenera
cat access.log
echo '<h1>Nowy plik</h1>' > nowy_plik.html
docker cp nowy_plik.html moj-serwer-www:/var/www/html/     # Do kontenera
curl http://localhost:8080/nowy_plik.html

# --- Inspekcja i diagnostyka kontenera ---
docker inspect moj-serwer-www          # Pełne informacje JSON
docker inspect -f '{{.State.Status}}' moj-serwer-www   # pojedyncze pole
docker stats --no-stream               # Monitor zasobów (bez --no-stream: na żywo)
docker top moj-serwer-www              # Procesy w kontenerze
docker diff moj-serwer-www             # Zmodyfikowane pliki

# --- Usuwanie kontenera ---
docker stop moj-serwer-www && docker rm moj-serwer-www
docker rm -f api-server        # Wymuszone (zatrzymuje i usuwa)
docker container prune -f      # Usuń wszystkie zatrzymane kontenery
rm -f access.log nowy_plik.html

# --- Dodatkowo: cykl życia krok po kroku ---
docker create --name cykl busybox:1.37 sleep 300              # created
docker start cykl                                             # running
docker stop -t 10 cykl                                        # SIGTERM, po 10 s SIGKILL → exited (137)
docker ps -a --filter name=cykl --format '{{.Names}}: {{.Status}}'
docker rm cykl                                                # removed
