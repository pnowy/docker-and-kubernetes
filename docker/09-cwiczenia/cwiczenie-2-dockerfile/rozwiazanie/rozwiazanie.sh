#!/usr/bin/env bash
# Ćwiczenie II – Modyfikacja Dockerfile (rozwiązanie; Dockerfile w tym katalogu ma już zmiany z kroków 10–11)
set -euo pipefail
cd "$(dirname "$0")"

# 11. Utwórz plik alx.html
echo '<h1>Hello ALX</h1>' > alx.html

# 12. Zbuduj nowy obraz i zweryfikuj jego działanie
docker build -t moj-apache:2.0 .
docker run -d -p 8081:80 --name test-apache moj-apache:2.0
sleep 2
curl http://localhost:8081/alx.html

# Sprzątanie: docker rm -f test-apache
