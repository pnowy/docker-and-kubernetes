#!/usr/bin/env bash
# Sekcja 14 – Prywatny rejestr obrazów (registry:2). Wymaga obrazu moj-apache:1.0 z sekcji 4 (../04-dockerfile/build.sh).
# Port 5000 zajęty? (macOS: AirPlay Receiver) – użyj -p 5001:5000 i localhost:5001 w kolejnych poleceniach.

# Uruchom lokalny rejestr na porcie 5000
# Linux – dane w katalogu hosta (jak w materiałach):
#   docker run -d -p 5000:5000 --name registry -v /opt/registry:/var/lib/registry registry:2
# Docker Desktop (macOS/Windows) – /opt nie jest udostępniony maszynie wirtualnej ("mounts denied"), używamy woluminu:
docker run -d -p 5000:5000 --name registry -v registry-data:/var/lib/registry registry:2

# Otaguj i wypchnij do lokalnego rejestru
docker tag moj-apache:1.0 localhost:5000/moj-apache:1.0
docker push localhost:5000/moj-apache:1.0
curl http://localhost:5000/v2/_catalog              # lista obrazów w rejestrze
curl http://localhost:5000/v2/moj-apache/tags/list  # lista tagów

# Pobranie z rejestru – najpierw usuń lokalną kopię
docker rmi localhost:5000/moj-apache:1.0
docker pull localhost:5000/moj-apache:1.0
docker image inspect -f '{{json .RepoDigests}}' localhost:5000/moj-apache:1.0   # digest nadany przez rejestr

# Docker Hub – limity pobrań dla użytkowników anonimowych są niższe niż dla zalogowanych
# docker login
# docker tag moj-apache:1.0 <login>/moj-apache:1.0 && docker push <login>/moj-apache:1.0

# GitHub Container Registry (token z uprawnieniem write:packages)
# echo "$GITHUB_TOKEN" | docker login ghcr.io -u <login> --password-stdin
# docker tag moj-apache:1.0 ghcr.io/<login>/moj-apache:1.0 && docker push ghcr.io/<login>/moj-apache:1.0

# Sprzątanie: docker rm -f registry && docker volume rm registry-data
