#!/usr/bin/env bash
# Sekcja 3 – Warstwy obrazu i copy-on-write (animacja „Warstwy” w prezentacji)

# Obraz to stos warstw tylko do odczytu – każda instrukcja zmieniająca pliki dodaje warstwę
docker pull nginx:1.29
docker history nginx:1.29
docker image inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' nginx:1.29

# Dwa kontenery z jednego obrazu – współdzielą warstwy obrazu, każdy ma własną cienką warstwę zapisu
docker run -d --name w1 nginx:1.29
docker run -d --name w2 nginx:1.29

# Zapis w kontenerze trafia do jego warstwy zapisu (copy-on-write) – obraz i drugi kontener się nie zmieniają
docker exec w1 sh -c 'echo "<h1>zmienione w w1</h1>" > /usr/share/nginx/html/index.html'
docker exec w1 rm /usr/share/nginx/html/50x.html              # usunięcie = znacznik "whiteout" w warstwie zapisu
docker exec w1 head -1 /usr/share/nginx/html/index.html
docker exec w2 head -4 /usr/share/nginx/html/index.html       # w2 widzi oryginał
docker diff w1                                                # C = zmieniony, A = dodany, D = usunięty

# SIZE = warstwa zapisu kontenera, "virtual" = warstwa zapisu + warstwy obrazu (liczone raz na dysku)
docker ps -s --filter name=w1 --filter name=w2 --format 'table {{.Names}}\t{{.Size}}'

# Usunięcie kontenera usuwa jego warstwę zapisu – zmiany przepadają
docker rm -f w1 w2
docker run --rm nginx:1.29 head -4 /usr/share/nginx/html/index.html
