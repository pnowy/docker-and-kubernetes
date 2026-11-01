#!/usr/bin/env bash
# Sekcja 5 – Polityki restartu i limity zasobów

# --- Polityki restartu: no (domyślna), on-failure[:N], always, unless-stopped ---
# Proces kończy się błędem po 1 s – Docker uruchomi go ponownie maksymalnie 3 razy
docker run -d --name awaria --restart on-failure:3 busybox:1.37 sh -c 'echo start; sleep 1; exit 1'
sleep 15
docker inspect -f 'Restartów: {{.RestartCount}}, status: {{.State.Status}}, kod wyjścia: {{.State.ExitCode}}' awaria
docker logs awaria                                            # 4 × "start" – pierwsze uruchomienie + 3 restarty
docker update --restart unless-stopped awaria                 # politykę można zmienić bez tworzenia kontenera
docker rm -f awaria

# --- Limity zasobów (cgroups) ---
docker run -d --name limity --memory=256m --cpus=0.5 nginx:1.29
docker stats --no-stream limity                               # kolumna MEM USAGE / LIMIT pokazuje 256MiB
docker inspect -f 'Memory={{.HostConfig.Memory}} NanoCpus={{.HostConfig.NanoCpus}}' limity
docker rm -f limity

# Przekroczenie limitu pamięci → jądro zabija proces (OOM killer), kod wyjścia 137
docker run --name oom --memory=64m busybox:1.37 sh -c 'x=a; while true; do x=$x$x; done'
docker inspect -f 'OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}' oom
docker rm oom
