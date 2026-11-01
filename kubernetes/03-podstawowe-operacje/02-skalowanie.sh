#!/usr/bin/env bash
# 3.2 Skalowanie aplikacji. Wymaga nginx-deployment (01-pody-i-deploymenty.sh) i addonu metrics-server.
cd "$(dirname "$0")" || exit 1

# Ręczne skalowanie
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods -w            # obserwuj nowe Pody (Ctrl+C)
kubectl scale deployment nginx-deployment --replicas=3

# Horizontal Pod Autoscaler – wymagany Metrics Server (minikube addons enable metrics-server)
kubectl top pods               # pierwsze metryki ok. minutę po włączeniu addonu
# Materiały: --cpu-percent=50 – flaga przestarzała w kubectl 1.37, zastępuje ją --cpu=50%
kubectl autoscale deployment nginx-deployment --cpu=50% --min=2 --max=10
kubectl get hpa
kubectl delete hpa nginx-deployment

# Lub deklaratywnie przez manifest
kubectl apply -f hpa.yaml

# Obciążenie: 4 Pody, które bez przerwy odpytują nginx przez Service (Service omawiamy w sekcji 4)
kubectl expose deployment nginx-deployment --port=80
kubectl create deployment obciazenie --image=busybox:1.37 --replicas=4 -- \
  sh -c 'while true; do wget -q -O /dev/null http://nginx-deployment; done'
kubectl get hpa nginx-hpa -w   # po 1–2 min TARGETS > 50% i REPLICAS rośnie do 5–6 (Ctrl+C)

# Koniec obciążenia – HPA zmniejsza liczbę replik po ok. 5 min (okno stabilizacji)
kubectl delete deployment obciazenie
kubectl delete -f hpa.yaml
kubectl delete service nginx-deployment
