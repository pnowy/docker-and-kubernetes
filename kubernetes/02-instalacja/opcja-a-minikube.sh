#!/usr/bin/env bash
# 2.3 Opcja A: minikube – klaster, na którym robimy sekcje 1–6 i 8–11.
# Polecenia instalacji są dla jump-boxa (Linux amd64); macOS: brew install minikube kubectl.

# 7. Zainstaluj minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# 8. Zainstaluj kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
kubectl version --client

# 9. Uruchom klaster
# --cni=calico: domyślna sieć minikube nie egzekwuje NetworkPolicy (sekcja 4).
# Jump-box z co najmniej 16 GB RAM: --cpus=4 --memory=8192 – stos monitoringu z sekcji 9 potrzebuje ok. 2 GB.
minikube start --driver=docker --cni=calico --cpus=2 --memory=4096
minikube status
kubectl get nodes

# 10. Zainstaluj przydatne addony
minikube addons enable metrics-server   # kubectl top, HPA (sekcja 3)
minikube addons enable ingress          # kontroler Ingress NGINX (sekcja 4)
minikube addons enable headlamp         # UI zamiast wycofanego Kubernetes Dashboard (sekcja 6)
minikube addons list | grep enabled

# 11. Otwórz UI: Headlamp zamiast Dashboard
kubectl -n headlamp rollout status deploy/headlamp
kubectl -n headlamp create token headlamp --duration 24h   # token do logowania
kubectl -n headlamp port-forward svc/headlamp 8080:80      # http://localhost:8080 (Ctrl+C kończy)
# Z laptopa do jump-boxa: ssh -L 8080:localhost:8080 <użytkownik>@<jump-box>

# Zatrzymanie i usunięcie klastra (dane w klastrze znikają przy delete)
# minikube stop
# minikube delete
