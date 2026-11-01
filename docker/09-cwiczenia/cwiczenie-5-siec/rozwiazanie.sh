#!/usr/bin/env bash
# Ćwiczenie V – Sieć wielokontenerowa

# 22. Utwórz dedykowaną sieć dla aplikacji
docker network create moja-app-siec

# 23. Uruchom kontener z bazą danych
docker run -d --name baza --network moja-app-siec \
  -e MYSQL_ROOT_PASSWORD=secret -e MYSQL_DATABASE=testdb mariadb

# 24. Uruchom kontener aplikacji w tej samej sieci (interaktywnie)
echo "Wewnątrz kontenera wykonaj:"
echo "  apt-get update && apt-get install -y mysql-client"
echo "  mysql -h baza -u root -psecret testdb"
docker run -it --rm --network moja-app-siec ubuntu bash

# Sprzątanie: docker rm -f baza && docker network rm moja-app-siec
