#!/usr/bin/env bash
# ★ Ćwiczenie sekcji 3: notes-api w klastrze – Deployment, ConfigMap, sondy, rolling update i rollback
cd "$(dirname "$0")" || exit 1

# 1. Obraz notes-api w klastrze: zbuduj (albo użyj obrazu z części Docker) i skopiuj do minikube
docker build -t notes-api:1.0.0 ../../../app-node
docker tag notes-api:1.0.0 notes-api:1.1.0
minikube image load notes-api:1.0.0
minikube image load notes-api:1.1.0
minikube image ls | grep notes-api

# 2. Namespace i Deployment z ConfigMap, sondami i zasobami
kubectl create namespace notes
kubectl apply -f rozwiazanie/notes-api.yaml
kubectl -n notes rollout status deployment/notes-api
kubectl -n notes get pods -o wide

# 3. Test przez port-forward (w drugim terminalu: curl)
kubectl -n notes port-forward deployment/notes-api 8000:3000 &
sleep 2
curl -s localhost:8000/; echo                       # "version":"1.0.0","storage":"json"
curl -s -X POST localhost:8000/notes -H 'Content-Type: application/json' -d '{"text":"Pierwsza notatka z K8s"}'; echo
curl -s localhost:8000/notes; echo
kill %1

# 4. Rolling update do 1.1.0: nowy obraz i nowa wersja w ConfigMap
kubectl -n notes patch configmap notes-config --type=merge -p '{"data":{"APP_VERSION":"1.1.0"}}'
kubectl -n notes set image deployment/notes-api api=notes-api:1.1.0
kubectl -n notes annotate deployment/notes-api kubernetes.io/change-cause="notes-api 1.1.0" --overwrite
kubectl -n notes rollout status deployment/notes-api
kubectl -n notes exec deploy/notes-api -- printenv APP_VERSION   # 1.1.0 – nowe Pody czytają ConfigMap przy starcie

# 5. Nieudana aktualizacja: obraz, którego nie ma
kubectl -n notes set image deployment/notes-api api=notes-api:9.9.9
kubectl -n notes annotate deployment/notes-api kubernetes.io/change-cause="notes-api 9.9.9" --overwrite
kubectl -n notes rollout status deployment/notes-api --timeout=30s   # timeout: nowy Pod nie startuje
kubectl -n notes get pods                                           # ErrImagePull/ImagePullBackOff + 2 stare Pody Running
kubectl -n notes rollout history deployment/notes-api
kubectl -n notes rollout undo deployment/notes-api
kubectl -n notes rollout status deployment/notes-api
kubectl -n notes get deployment notes-api -o jsonpath='{.spec.template.spec.containers[0].image}'; echo   # notes-api:1.1.0

# Namespace notes zostaw – sekcja 4 dodaje do niego Service i Ingress.
