#!/usr/bin/env bash
# Krok 4: testowa aplikacja nginx – uruchom na masterze, gdy wszystkie węzły są Ready
set -euo pipefail

kubectl create namespace testowa --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment test-nginx --image=nginx:1.29 --replicas=2 -n testowa
kubectl expose deployment test-nginx --port=80 --type=NodePort -n testowa

# Poprawka: czekaj na gotowość Deploymentu zamiast od razu listować Pody
kubectl rollout status deployment/test-nginx -n testowa --timeout=120s
kubectl get pods -n testowa -o wide

NODE_PORT=$(kubectl get svc test-nginx -n testowa -o jsonpath='{.spec.ports[0].nodePort}')
echo "Przetestuj: curl http://<IP_DOWOLNEGO_NODE>:${NODE_PORT}"
