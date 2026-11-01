#!/usr/bin/env bash
# ★ Ćwiczenie sekcji 6: własny chart notes-api (notes-api-chart/). Wymaga obrazu notes-api:1.1.0 w minikube (sekcja 3).
cd "$(dirname "$0")" || exit 1
INGRESS_IP=$(minikube ip)   # macOS/Windows: minikube tunnel w osobnym terminalu i INGRESS_IP=127.0.0.1

# Sprawdź chart, zanim cokolwiek trafi do klastra
helm lint notes-api-chart
helm template notes notes-api-chart | less                         # gotowe manifesty
helm template notes notes-api-chart --set storage=postgres | grep -A6 'kind: ConfigMap' -m1

# Dwa środowiska z jednego chartu: różnią się tylko values
helm install notes notes-api-chart -n notes-helm --create-namespace
helm install notes-staging notes-api-chart -n notes-staging --create-namespace -f notes-api-chart/values-staging.yaml
helm list -A
kubectl -n notes-helm rollout status deployment/notes
kubectl -n notes-helm wait ingress/notes --for=jsonpath='{.status.loadBalancer.ingress}' --timeout=90s
curl -s -H "Host: notes-helm.local" "http://${INGRESS_IP}/"; echo

# Upgrade wartości i rollback
helm upgrade notes notes-api-chart -n notes-helm --set replicaCount=3
kubectl -n notes-helm get pods
helm history notes -n notes-helm
helm rollback notes 1 -n notes-helm

# Sprzątanie
helm uninstall notes -n notes-helm
helm uninstall notes-staging -n notes-staging
kubectl delete namespace notes-helm notes-staging
