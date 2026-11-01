#!/usr/bin/env bash
# Sekcja 5 – Logi kontenerów: stdout/stderr, sterowniki logowania, rotacja

# Aplikacja w kontenerze pisze na stdout/stderr – Docker zbiera to przez sterownik logowania
docker run -d --name gadula busybox sh -c 'i=0; while true; do i=$((i+1)); echo "linia $i"; echo "błąd $i" >&2; sleep 0.1; done'
sleep 3
docker logs --tail 4 gadula
docker logs --tail 2 --timestamps gadula
docker logs --since 2s gadula 2>&1 | wc -l   # tylko ostatnie 2 sekundy
docker logs gadula 2>/dev/null | tail -1    # stdout i stderr to osobne strumienie

# Domyślny sterownik Docker Engine to json-file (bez rotacji!); Docker Desktop ustawia local – sprawdź:
docker info --format '{{.LoggingDriver}}'
docker inspect --format '{{.HostConfig.LogConfig.Type}} {{.LogPath}}' gadula
docker rm -f gadula

# json-file: plik JSON na hoście (w Docker Desktop – w maszynie wirtualnej); rotacja: maks. 3 pliki po 1 MB
docker run -d --name rotacja --log-driver json-file --log-opt max-size=1m --log-opt max-file=3 busybox \
  sh -c 'while true; do head -c 2000 /dev/zero | tr "\0" x; echo; done'
sleep 5
docker inspect --format '{{.HostConfig.LogConfig.Config}}' rotacja
# Rozmiar plików logu – podgląd z wnętrza maszyny Docker Desktop (na Linuksie wystarczy ls -lh na hoście)
docker run --rm --privileged --pid=host alpine nsenter -t 1 -m -- sh -c \
  "ls -lh \$(dirname $(docker inspect --format '{{.LogPath}}' rotacja))" 2>/dev/null | grep json
docker rm -f rotacja

# Sterownik local: binarny format, domyślnie rotacja (5 plików × 20 MB), docker logs działa
docker run -d --name lokalny --log-driver local busybox sh -c 'echo z local; sleep 30'
sleep 1; docker logs lokalny
docker rm -f lokalny

# Sterownik none: logi wyłączone – docker logs nie ma czego pokazać
docker run -d --name cichy --log-driver none busybox sh -c 'echo nikt mnie nie usłyszy; sleep 30'
sleep 1; docker logs cichy                  # błąd: configured logging driver does not support reading
docker rm -f cichy

# Ustawienie globalne – /etc/docker/daemon.json (Docker Desktop: Settings → Docker Engine),
# dotyczy tylko NOWYCH kontenerów, wymaga restartu daemona:
cat <<'EOF'
{
  "log-driver": "local",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF

# Compose – logi wszystkich serwisów z prefiksem nazwy, opcje sterownika w compose.yaml:
#   docker compose logs -f --tail 20
#   services:
#     api:
#       logging:
#         driver: json-file
#         options: { max-size: "10m", max-file: "3" }
