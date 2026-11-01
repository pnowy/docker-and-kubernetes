#!/usr/bin/env bash
# Sekcja 6 – Woluminy, bind mounty i tmpfs. Bind mount używa obrazu moj-apache:1.0 z sekcji 4 (../04-dockerfile/build.sh).
cd "$(dirname "$0")" || exit 1

# --- Zarządzanie woluminami ---
docker volume create moje-dane
docker volume ls
docker volume inspect moje-dane   # Pokazuje ścieżkę na hoście i metadane (w Docker Desktop: wewnątrz VM)
docker volume rm moje-dane
# docker volume prune             # Usuń nieużywane woluminy (pyta o potwierdzenie)

# --- Named volume – baza MariaDB ---
docker run -d --name moja-baza \
  -e MYSQL_ROOT_PASSWORD=sekret \
  -v moje-dane-db:/var/lib/mysql \
  mariadb
sleep 10
docker exec moja-baza mariadb -uroot -psekret -e 'CREATE DATABASE szkolenie;'

# --- Bind mount – development (katalog projektu) ---
mkdir -p src && echo '<h1>Plik z hosta (bind mount)</h1>' > src/index.html
docker run -d --name dev-server \
  -v $(pwd)/src:/var/www/html \
  -p 8080:80 moj-apache:1.0
sleep 2 && curl -s http://localhost:8080/   # edytuj src/index.html i odśwież – zmiana widoczna od razu

# --- Składnia --mount (bardziej czytelna) – ten sam wolumin w nowym kontenerze ---
docker rm -f moja-baza
docker run -d --name moja-baza \
  --mount source=moje-dane-db,target=/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=sekret \
  mariadb
sleep 5
docker exec moja-baza mariadb -uroot -psekret -e 'SHOW DATABASES LIKE "szkolenie";'   # baza przetrwała usunięcie kontenera

# --- tmpfs – dane tylko w pamięci RAM ---
docker run --rm --tmpfs /tmp/cache:size=64m ubuntu:20.04 df -h /tmp/cache

# --- Dodatkowo: wolumin tylko do odczytu, zawartość z obrazu, kopia zapasowa ---
docker run --rm -v "$(pwd)/src:/dane:ro" ubuntu:20.04 touch /dane/x || echo "Zapis zablokowany (:ro)"
docker run --rm -v html-z-obrazu:/usr/share/nginx/html nginx:1.29 true
docker run --rm -v html-z-obrazu:/dane busybox:1.37 ls /dane  # 50x.html index.html – pusty wolumin dostał pliki z obrazu
docker run --rm -v moje-dane-db:/dane:ro -v "$(pwd):/backup" ubuntu:20.04 tar czf /backup/moje-dane-db.tgz -C /dane .
ls -lh moje-dane-db.tgz
# Odtworzenie: docker run --rm -v nowy-wolumin:/dane -v "$(pwd):/backup" ubuntu:20.04 tar xzf /backup/moje-dane-db.tgz -C /dane

# --- Sprzątanie ---
docker rm -f moja-baza dev-server
docker volume rm moje-dane-db html-z-obrazu
rm -rf src moje-dane-db.tgz
