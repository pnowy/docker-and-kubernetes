#!/usr/bin/env bash
# 2.3 Opcja C: k3s (produkcja/edge) – tylko Linux.
# Uwaga: instaluje usługę systemową k3s z własnym containerd. Uruchamiaj na osobnej maszynie, nie na jump-boxie z minikube.

# 15. Instalacja jedną komendą
curl -sfL https://get.k3s.io | sh -
sudo k3s kubectl get nodes

# Odinstalowanie
# sudo /usr/local/bin/k3s-uninstall.sh
