#!/usr/bin/env bash
# Sekcja 4 – Budowanie obrazu Apache (uruchom w katalogu z Dockerfile i index.html)
set -euo pipefail
cd "$(dirname "$0")" || exit 1

docker build -t moj-apache:1.0 .
# docker build -t moj-apache:1.0 --no-cache .         # bez użycia cache
# docker build --progress=plain -t moj-apache:1.0 .   # pełny log każdego kroku

# Tag używany w ćwiczeniu IV (sekcja 9)
docker tag moj-apache:1.0 ubuntu_apache
docker images moj-apache

docker run -d --name apache-test -p 8080:80 moj-apache:1.0
sleep 6
docker ps --filter name=apache-test --format '{{.Names}}: {{.Status}}'   # (healthy) – wynik HEALTHCHECK
curl -s http://localhost:8080/
docker rm -f apache-test
