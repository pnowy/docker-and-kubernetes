#!/usr/bin/env bash
# Sekcja 2 – Instalacja Docker Engine na Ubuntu (np. maszyna wirtualna) wg https://docs.docker.com/engine/install/ubuntu/
set -euo pipefail

# 1. Klucz GPG Dockera
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 2. Repozytorium apt Dockera (format deb822, architektura wykrywana automatycznie)
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<SOURCES
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
SOURCES

# 3. Docker Engine z pluginami Buildx i Compose
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Weryfikacja instalacji
sudo docker run --rm hello-world
docker --version
docker compose version

# 5. Praca bez sudo (opcjonalne) – członkostwo w grupie docker daje uprawnienia równoważne root
sudo usermod -aG docker "$USER"
echo "Wyloguj się i zaloguj ponownie (lub wykonaj: newgrp docker), aby używać dockera bez sudo."
