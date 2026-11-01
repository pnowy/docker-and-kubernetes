#!/usr/bin/env bash
# Sekcja 15 – Troubleshooting: typowe problemy. Wykonuj polecenia pojedynczo.

# --- Kontener natychmiast się zatrzymuje ---
docker run -d --name moj-kontener ubuntu:24.04                # bash bez terminala (-it) od razu się kończy
docker ps -a --filter name=moj-kontener --format '{{.Names}}: {{.Status}}'   # Exited (0)
docker logs moj-kontener                                      # zawsze zacznij od logów
docker inspect -f '{{.State.ExitCode}} {{.State.Error}}' moj-kontener
docker run --rm --entrypoint sh notes-api:1.0.0 -c 'ls -l /app && id'      # wejście do obrazu z pominięciem ENTRYPOINT
docker rm moj-kontener

# --- Kody wyjścia: 0 – OK, 1 – błąd aplikacji, 125 – błąd docker run, 126/127 – polecenie nie do uruchomienia / nie istnieje,
#     137 – SIGKILL (OOM albo docker kill / stop po timeoucie), 143 – SIGTERM ---
docker run --rm ubuntu:24.04 nieistniejace-polecenie; echo "kod: $?"          # 127
docker run --rm --memory=64m busybox:1.37 sh -c 'x=a; while true; do x=$x$x; done'; echo "kod: $?"   # 137

# --- Aplikacja nie łączy się z bazą (zła nazwa hosta, inna sieć, baza jeszcze nie gotowa) ---
docker run -d --name api-bez-bazy -e PGHOST=db -p 8000:3000 notes-api:1.0.0
sleep 3
docker logs api-bez-bazy | tail -2                            # "Baza niedostępna (getaddrinfo ENOTFOUND db)"
curl -s http://localhost:8000/readyz; echo                    # {"ready":false}
docker rm -f api-bez-bazy

# --- Port zajęty ---
docker run -d --name zajmuje-port -p 8080:80 nginx:1.29
docker run -d --name konflikt -p 8080:80 nginx:1.29 || echo "Port 8080 jest już zajęty – użyj innego portu hosta"
docker rm -f zajmuje-port konflikt
# Kto zajmuje port na hoście: lsof -nP -iTCP:8080 -sTCP:LISTEN (macOS/Linux), netstat -ano | findstr 8080 (Windows)

# --- Permission denied przy bind mount (UID w kontenerze ≠ UID właściciela na hoście) ---
docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd):/data" ubuntu:24.04 touch /data/test-uid
ls -ln test-uid && rm test-uid
# W Dockerfile: COPY --chown=node:node … albo RUN chown -R appuser:appuser /app

# --- Kontenery nie widzą się po nazwach ---
docker run -d --name kontener1 busybox:1.37 sleep 300
docker run -d --name kontener2 busybox:1.37 sleep 300
docker exec kontener1 ping -c1 -W1 kontener2 || echo "Brak DNS w domyślnej sieci bridge"
docker network create moja-siec
docker network connect moja-siec kontener1
docker network connect moja-siec kontener2
docker exec kontener1 ping -c1 kontener2                      # działa w sieci użytkownika
docker rm -f kontener1 kontener2 && docker network rm moja-siec

# --- Diagnostyka kontenera bez powłoki (distroless) ---
# docker debug <kontener>                                     # Docker Desktop: powłoka z narzędziami doklejona do kontenera
docker run -d --name bez-powloki gcr.io/distroless/nodejs24-debian13 -e 'setInterval(() => {}, 1000)'
docker run --rm --pid container:bez-powloki --network container:bez-powloki busybox:1.37 ps   # kontener "obok" ze wspólnym PID i siecią
docker rm -f bez-powloki

# --- Brak miejsca na dysku ---
docker system df                                              # co zajmuje miejsce
docker builder prune -f                                       # cache buildera
docker container prune -f                                     # zatrzymane kontenery
docker image prune -f                                         # obrazy dangling
# docker system prune -a --volumes                            # WSZYSTKO nieużywane, łącznie z woluminami – uwaga!
