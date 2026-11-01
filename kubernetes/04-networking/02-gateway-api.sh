#!/usr/bin/env bash
# ★ Gateway API – następca Ingress. Kontroler: Envoy Gateway. Wymaga Serwisu notes-api z ćwiczenia sekcji 4 (albo kroku 0).
cd "$(dirname "$0")" || exit 1

# 0. Przygotowanie – tylko gdy ćwiczeń ★ notes-api z sekcji 3 i 4 nie robiliśmy.
#    Sprawdź: kubectl -n notes get service notes-api – jeśli istnieje, przejdź do instalacji kontrolera.
docker build -t notes-api:1.0.0 ../../app-node
minikube image load notes-api:1.0.0                            # obraz tylko w klastrze, bez rejestru
kubectl create namespace notes
kubectl apply -f ../03-podstawowe-operacje/cwiczenie-notes-api/rozwiazanie/notes-api.yaml   # ConfigMap + Deployment
kubectl apply -f cwiczenie-notes-api/notes-api-siec.yaml       # Service notes-api (port 80 → 3000) + Ingress
kubectl -n notes rollout status deployment/notes-api

# Instalacja kontrolera razem z CRD Gateway API (Helm omawiamy w sekcji 6)
helm install eg oci://docker.io/envoyproxy/gateway-helm --version 1.9.3 \
  -n envoy-gateway-system --create-namespace
kubectl -n envoy-gateway-system wait --for=condition=Available deployment/envoy-gateway --timeout=5m
kubectl api-resources --api-group=gateway.networking.k8s.io   # nowe typy: GatewayClass, Gateway, HTTPRoute...

# GatewayClass + Gateway + HTTPRoute
kubectl apply -f gateway.yaml
kubectl -n notes wait --for=condition=Accepted gateway/notes-gateway --timeout=2m
kubectl -n notes get gateway,httproute   # PROGRAMMED: False, dopóki Serwis LoadBalancer nie dostanie adresu (minikube tunnel)
kubectl -n envoy-gateway-system get pods,services   # Envoy dla notes-gateway: osobny Deployment i Service LoadBalancer

# Test przez port-forward do Serwisu Envoy (albo: minikube tunnel i EXTERNAL-IP Serwisu)
ENVOY_SVC=$(kubectl -n envoy-gateway-system get service \
  -l gateway.envoyproxy.io/owning-gateway-name=notes-gateway -o jsonpath='{.items[0].metadata.name}')
kubectl -n envoy-gateway-system port-forward "service/${ENVOY_SVC}" 8888:80 &
sleep 2
curl -s -H "Host: notes.local" http://localhost:8888/; echo
curl -s -o /dev/null -w '%{http_code}\n' -H "Host: inny.local" http://localhost:8888/   # 404 – brak HTTPRoute dla tego hosta
kill %1

# Sprzątanie
# kubectl delete -f gateway.yaml
# helm uninstall eg -n envoy-gateway-system
