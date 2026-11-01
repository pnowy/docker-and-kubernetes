#!/usr/bin/env bash
# Ćwiczenie III – Uruchamianie kontenerów MariaDB

# 13. Uruchom kontener mariadb
docker run -d --name moja-baza -e MYSQL_ROOT_PASSWORD=tajnehaslo mariadb

# 14. Sprawdź adres IP kontenera
docker inspect moja-baza | grep IPAddress

# 15. Uruchom nowy kontener z mapowaniem portu
docker run -d --name moja-baza2 -p 3306:3306 -e MYSQL_ROOT_PASSWORD=tajnehaslo mariadb

# 16. Uruchom powłokę w kontenerze i sprawdź procesy (interaktywnie):
#   docker exec -it moja-baza2 bash
#   # Wewnątrz kontenera:
#   ps auxf
#   mariadb -u root -ptajnehaslo -e "SHOW DATABASES;"   # w PDF: mysql – w aktualnym obrazie klient nazywa się mariadb
#   exit
sleep 10
docker exec moja-baza2 ps auxf
docker exec moja-baza2 mariadb -u root -ptajnehaslo -e "SHOW DATABASES;"

# 17. Sprawdź zmodyfikowane pliki w kontenerze
docker diff moja-baza2

# Sprzątanie: docker rm -f moja-baza moja-baza2
