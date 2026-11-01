#!/usr/bin/env bash
# 2.3 Opcja B: kind (Kubernetes in Docker). macOS: brew install kind
cd "$(dirname "$0")" || exit 1

# 12. Zainstaluj kind (materiały: v0.20.0 – tu aktualna wersja)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind
kind version

# 13. Utwórz klaster
kind create cluster --name moj-klaster
kubectl config current-context   # kind-moj-klaster – kind przełączył kubectl na nowy klaster

# 14. Utwórz klaster wielowęzłowy (z plikiem konfiguracyjnym kind-config.yaml)
kind delete cluster --name moj-klaster
kind create cluster --name moj-klaster --config kind-config.yaml
kubectl get nodes
docker ps --filter label=io.x-k8s.kind.cluster=moj-klaster   # każdy węzeł to kontener Dockera

# Powrót do minikube i sprzątanie
kind delete cluster --name moj-klaster
kubectl config use-context minikube
