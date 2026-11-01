#!/usr/bin/env bash
# Sekcja 4 – ENTRYPOINT i CMD w trzech krokach
cd "$(dirname "$0")" || exit 1

# --- 1. Samo CMD: domyślne polecenie, argumenty docker run zastępują je w całości ---
docker build -q -t demo-cmd -f Dockerfile.cmd .
docker run --rm demo-cmd                         # Domyślne polecenie z CMD
docker run --rm demo-cmd ls /                    # zamiast CMD: ls /

# --- 2. ENTRYPOINT + CMD: program stały, argumenty docker run zastępują tylko CMD ---
docker build -q -t demo-entrypoint -f Dockerfile.entrypoint .
docker run --rm demo-entrypoint                  # Witaj, świecie
docker run --rm demo-entrypoint ALX              # Witaj, ALX
docker run --rm --entrypoint echo demo-entrypoint Hello, world   # nowy program – CMD z obrazu znika, argumenty podajesz sam

# --- 3. Skrypt startowy: ENTRYPOINT ["entrypoint.sh"] + CMD ["node", "dist/server.js"] ---
docker build -q -t notes-api:json --build-arg STORAGE=json ../../../app-node
docker build -q -t demo-skrypt -f Dockerfile.skrypt .
docker run -d --name demo-skrypt -p 8000:3000 demo-skrypt
sleep 2
docker logs demo-skrypt                          # najpierw komunikaty skryptu, potem start aplikacji
curl -s http://localhost:8000/notes; echo        # notatka utworzona przez entrypoint.sh
docker exec demo-skrypt cat /proc/1/cmdline | tr '\0' ' '; echo   # PID 1 = node dist/server.js – exec zastąpił powłokę
time docker stop demo-skrypt                     # ułamek sekundy – SIGTERM trafił prosto do node, kod 0
docker rm demo-skrypt
docker run --rm demo-skrypt node -e 'console.log("inne polecenie")'   # skrypt wykona się zawsze, CMD zastąpione

# Dla chętnych: usuń "exec" z entrypoint.sh, przebuduj i powtórz – docker stop czeka do limitu czasu (10 s, Docker Desktop 3 s) i kończy kodem 137
