#!/usr/bin/env bash
# Ćwiczenie IV – Woluminy i trwałość danych
# Wymaga obrazu ubuntu_apache – zbuduj go: ../../04-dockerfile/build.sh

# 18. Utwórz wolumin i uruchom kontener ubuntu_apache
docker volume create www-data
docker run -d --name moj-apache-wolumin -v www-data:/var/www/html/alx ubuntu_apache
# Utwórz plik w woluminie na hoście – tylko Linux (Docker Engine):
#   sudo touch /var/lib/docker/volumes/www-data/_data/alx.html
# Docker Desktop (macOS/Windows) – wolumin jest w maszynie wirtualnej, użyj kontenera pomocniczego:
docker run --rm -v www-data:/data busybox touch /data/alx.html

# 19. Wejdź do kontenera, zweryfikuj pliki i zatrzymaj proces (interaktywnie):
#   docker exec -it moj-apache-wolumin bash
#   ls /var/www/html/alx/
#   ps aux | grep apache2
#   kill <PID>        # PID procesu "/usr/sbin/apache2 -D FOREGROUND" uruchomionego jako root
#   (kontener zatrzyma się – Apache zakończył pracę, więc kończy się też proces główny)
docker exec moj-apache-wolumin ls /var/www/html/alx/
docker exec moj-apache-wolumin bash -c 'ps aux | grep apache2'

# 20. Skopiuj plik do kontenera (działa także na zatrzymanym kontenerze)
touch kopiowanie.html
docker cp kopiowanie.html moj-apache-wolumin:/var/www/html/

# 21. Usuń kontener i zweryfikuj, że wolumin przetrwał
docker rm -f moj-apache-wolumin
docker volume ls | grep www-data
# Wolumin nadal istnieje – dane są trwałe!
# Uruchom nowy kontener z tym samym woluminem
docker run -d --name nowy-apache -v www-data:/var/www/html/alx ubuntu_apache
docker exec nowy-apache ls /var/www/html/alx/ /var/www/html/   # alx.html jest, kopiowanie.html – nie

# Sprzątanie: docker rm -f nowy-apache && docker volume rm www-data && rm kopiowanie.html
