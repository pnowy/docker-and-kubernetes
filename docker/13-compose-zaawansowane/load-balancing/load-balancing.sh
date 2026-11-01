#!/usr/bin/env bash
# Sekcja 13 – Skalowanie i load balancing: Nginx, HAProxy i Traefik przed replikami notes-api
cd "$(dirname "$0")" || exit 1

# Wymaga obrazu notes-api:1.0.0 (docker build -t notes-api:1.0.0 ../../../app-node)
docker compose config --services                # db, api (z app-node/ przez include), nginx, haproxy, traefik
docker compose up -d --wait
docker compose ps

# Rozkład ruchu: każda odpowiedź zawiera nazwę hosta repliki (ID kontenera)
rozklad() { for _ in $(seq 12); do curl -s "localhost:$1/" | sed -E 's/.*"hostname":"([^"]+)".*/\1/'; echo; done | sort | uniq -c; }
rozklad 8080    # Nginx
rozklad 8085    # HAProxy
rozklad 8088    # Traefik
curl -sI localhost:8080/ | grep -i x-upstream  # Nginx: adres repliki w nagłówku
curl -sI localhost:8085/ | grep -i x-server    # HAProxy: nazwa slotu serwera

# DNS serwisu zwraca adresy wszystkich replik
docker compose exec nginx nslookup api 127.0.0.11

# --- Skalowanie: proxy same odkrywają nowe repliki (DNS / etykiety Dockera) ---
docker compose up -d --scale api=5 --wait
sleep 6
rozklad 8080
echo "HAProxy – statystyki: http://localhost:8404   Traefik – dashboard: http://localhost:8089"

# --- Awaria repliki: zatrzymana i zamrożona ---
docker stop lb-api-2                           # zatrzymana: proxy ponawiają żądanie na innej replice (Nginx sporadycznie 502)
for p in 8080 8085 8088; do curl -s -o /dev/null -w "$p %{http_code}\n" "localhost:$p/"; done
docker start lb-api-2

docker pause lb-api-3                          # zamrożona: przyjmuje połączenie, ale nie odpowiada
sleep 5                                        # aktywne health checki HAProxy i Traefika (co 2 s) ją wykluczają
for p in 8080 8085 8088; do
  for _ in $(seq 6); do curl -s -m 10 -o /dev/null -w "%{http_code}/%{time_total}s " "localhost:$p/"; done; echo " ← $p"
done                                           # Nginx (open source, bez aktywnych checków): jedno żądanie czeka proxy_read_timeout
docker unpause lb-api-3
sleep 12                                       # healthcheck obrazu (co 10 s) musi znów zgłosić healthy

# Logi proxy – kto obsłużył żądanie
docker compose logs --tail 5 haproxy

# Powrót do 3 replik i sprzątanie (wolumin bazy lb_db-data zostaje bez -v)
docker compose up -d --scale api=3 --wait     # Nginx przez 5 s (valid=5s) może jeszcze trafić w usunięte repliki
# docker compose down -v
