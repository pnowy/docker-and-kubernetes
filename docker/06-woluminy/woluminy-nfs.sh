#!/usr/bin/env bash
# Sekcja 6 – Wolumin zdalny NFS (sterownik local z opcjami mount)
# Laboratorium: serwer NFS w kontenerze (obraz amd64 – na Apple Silicon działa przez emulację).
# W firmie zamiast niego jest serwer NFS/NAS, np. addr=nfs.firma.local,device=:/eksport/app

docker network create nfslab
docker run -d --name nfs-serwer --network nfslab --privileged --platform linux/amd64 \
  -e SHARED_DIRECTORY=/eksport -v nfs-eksport:/eksport itsthenetwork/nfs-server-alpine:12
sleep 8                                      # serwer startuje kilka sekund (komunikat "retrying" jest normalny)
NFS_IP=$(docker inspect -f '{{(index .NetworkSettings.Networks "nfslab").IPAddress}}' nfs-serwer)

# Wolumin montowany przez daemona przy starcie kontenera, nie przy tworzeniu
docker volume create --driver local \
  --opt type=nfs --opt o="addr=$NFS_IP,rw,nfsvers=4" --opt device=:/ dane-nfs
docker volume inspect dane-nfs --format '{{.Driver}} {{.Options}}'

docker run --rm -v dane-nfs:/dane alpine sh -c 'echo "zapis z kontenera" > /dane/plik.txt; mount | grep /dane'
docker exec nfs-serwer cat /eksport/plik.txt  # plik jest na serwerze NFS

# To samo w compose.yaml:
#   volumes:
#     dane-nfs:
#       driver: local
#       driver_opts:
#         type: nfs
#         o: "addr=nfs.firma.local,rw,nfsvers=4"
#         device: ":/eksport/app"
# Inne zdalne systemy: CIFS/SMB (type=cifs), wtyczki woluminów (np. sshfs, chmury) – docker plugin install

# Sprzątanie
docker volume rm dane-nfs
docker rm -f nfs-serwer
docker volume rm nfs-eksport
docker network rm nfslab
