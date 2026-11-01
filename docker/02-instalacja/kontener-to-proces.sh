#!/usr/bin/env bash
# Sekcja 2 – Ćwiczenie 2B: kontener to tylko proces (demo prowadzącego, polecenia pojedynczo)
set -euo pipefail

docker run -d --name proces busybox:1.37 sleep 600

# Jeden proces, dwa punkty widzenia
docker top proces                    # PID według hosta (na macOS/Windows: według VM Docker Desktop)
docker exec proces ps                # wewnątrz kontenera sleep ma PID 1
docker exec proces hostname          # osobna przestrzeń UTS – skrót ID kontenera

# Linux (Docker Engine): proces widać zwykłym ps na hoście
ps -ef | grep "[s]leep 600"

# macOS / Windows (Docker Desktop): host nie widzi procesu – jest w VM.
# Pomocniczy kontener ze wspólną przestrzenią PID z VM widzi wszystkie procesy, także rodzica containerd-shim
docker run --rm --pid=host busybox:1.37 ps -o pid,ppid,comm | grep -E "PID|sleep|shim"
docker run --rm --pid=host busybox:1.37 sh -c 'grep NSpid /proc/$(pidof sleep)/status'   # NSpid: <PID w VM> 1

# Wejście do samej VM Docker Desktop (przestrzenie nazw procesu 1 maszyny wirtualnej)
docker run --rm -it --privileged --pid=host busybox:1.37 nsenter -t 1 -m -u -n -i sh
#   w środku: hostname; uname -r; ps | grep sleep; exit

# Wspólne jądro
docker run --rm busybox:1.37 uname -r     # Linux: to samo co host; macOS: …-linuxkit; Windows: …-microsoft-standard-WSL2
uname -r

# Limity to cgroups
docker run -d --name limit --memory 64m --cpus 0.5 busybox:1.37 sleep 600
docker exec limit cat /sys/fs/cgroup/memory.max /sys/fs/cgroup/cpu.max   # 67108864 i 50000 100000

# Start w ułamku sekundy
time docker run --rm busybox:1.37 true

docker rm -f proces limit
