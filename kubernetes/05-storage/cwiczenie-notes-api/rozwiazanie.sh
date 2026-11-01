#!/usr/bin/env bash
# ★ Ćwiczenie sekcji 5: notes-api z PostgreSQL – Secret, StatefulSet z PVC, init container, Job.
# Wymaga namespace notes z ćwiczeń sekcji 3 i 4 (Deployment, Service, Ingress, NetworkPolicy).
cd "$(dirname "$0")" || exit 1
INGRESS_IP=$(minikube ip)   # macOS/Windows: minikube tunnel w osobnym terminalu i INGRESS_IP=127.0.0.1

# 1. Secret z hasłem – tworzony poleceniem, żeby hasło nie trafiło do repozytorium
kubectl -n notes create secret generic notes-db --from-literal=password=notes-haslo-szkoleniowe
kubectl -n notes get secret notes-db -o jsonpath='{.data.password}' | base64 -d; echo

# 2. Baza: StatefulSet z volumeClaimTemplates i headless Service; NetworkPolicy dla bazy
kubectl apply -f notes-db.yaml -f network-policy-db.yaml
kubectl -n notes rollout status statefulset/notes-db
kubectl -n notes get pvc                       # db-data-notes-db-0: Bound

# 3. notes-api przełączone na bazę (ConfigMap + init container + Secret jako plik)
kubectl apply -f notes-api-postgres.yaml
kubectl -n notes rollout status deployment/notes-api
curl -s -H "Host: notes.local" "http://${INGRESS_IP}/"; echo   # "storage":"postgres"

# 4. Wspólne dane: notatka zapisana przez jeden Pod jest widoczna we wszystkich
curl -s -X POST -H "Host: notes.local" -H 'Content-Type: application/json' -d '{"text":"Notatka w PostgreSQL"}' "http://${INGRESS_IP}/notes"; echo
for i in 1 2 3 4; do curl -s -H "Host: notes.local" "http://${INGRESS_IP}/notes"; echo; done
kubectl -n notes logs -l app=notes-api -c czekaj-na-baze --prefix   # "notes-db:5432 - accepting connections"

# 5. Job dopisuje notatkę bezpośrednio do bazy
kubectl apply -f seed-job.yaml
kubectl -n notes wait --for=condition=Complete job/notes-seed --timeout=2m
kubectl -n notes logs job/notes-seed            # INSERT 0 1

# 6. Trwałość: usuń Pod bazy – StatefulSet tworzy notes-db-0 z tym samym PVC
kubectl -n notes delete pod notes-db-0
kubectl -n notes wait --for=condition=Ready pod/notes-db-0 --timeout=2m
until curl -sf -H "Host: notes.local" "http://${INGRESS_IP}/notes"; do sleep 2; done; echo   # obie notatki są
