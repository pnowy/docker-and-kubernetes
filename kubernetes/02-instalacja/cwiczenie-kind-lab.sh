#!/usr/bin/env bash
# 2.5 Ćwiczenie: tworzenie przykładowego klastra kind (na jump-boxie, obok minikube)
# Porty 80 i 443 jump-boxa muszą być wolne – zajmie je węzeł control-plane klastra kind.
cd "$(dirname "$0")" || exit 1

# 16. Plik konfiguracyjny: klaster.yaml (w tym katalogu)
# 17. Utwórz klaster
kind create cluster --name lab-klaster --config klaster.yaml

# 18. Zweryfikuj węzły (NotReady przez kilkanaście sekund, dopóki nie wstanie sieć Podów)
kubectl wait --for=condition=Ready nodes --all --timeout=120s
kubectl get nodes -o wide

# 19. Sprawdź komponenty Control Plane
kubectl get pods -n kube-system

# 20. Załaduj lokalny obraz Docker do klastra kind (aplikacja notes-api z app-node/)
docker build -t moja-app:latest ../../app-node
kind load docker-image moja-app:latest --name lab-klaster
docker exec lab-klaster-worker crictl images | grep moja-app   # obraz jest w containerd węzła

# Dodatek przed krokiem 21: konteksty.sh – kubectx/kubens, póki kind działa

# 21. Usuń klaster po ćwiczeniu i wróć do minikube
kind delete cluster --name lab-klaster
kubectl config use-context minikube
