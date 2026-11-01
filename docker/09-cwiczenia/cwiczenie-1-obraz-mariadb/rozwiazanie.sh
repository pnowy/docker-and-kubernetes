#!/usr/bin/env bash
# Ćwiczenie I – Pobieranie i inspekcja obrazu MariaDB

# 7. Wyszukaj i pobierz obraz mariadb
docker search mariadb
docker pull mariadb

# 8. Sprawdź rozmiar i szczegóły obrazu
docker images mariadb
docker inspect mariadb

# 9. Sprawdź historię warstw obrazu
docker history mariadb
