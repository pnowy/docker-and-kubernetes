#!/usr/bin/env bash
# Sekcja 2 – Alternatywa: instalacja skryptem get.docker.com wg https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
# Tylko dla środowisk deweloperskich/szkoleniowych – nie na produkcji
set -euo pipefail

# Pobierz skrypt (przejrzyj go przed uruchomieniem: less get-docker.sh)
curl -fsSL https://get.docker.com -o get-docker.sh

# Podgląd kroków bez wprowadzania zmian
sudo sh ./get-docker.sh --dry-run

# Instalacja
sudo sh ./get-docker.sh
rm -f get-docker.sh

# Weryfikacja
sudo docker run hello-world
docker --version

# Praca bez sudo (opcjonalne)
sudo usermod -aG docker "$USER"
echo "Wyloguj się i zaloguj ponownie (lub wykonaj: newgrp docker), aby używać dockera bez sudo."
