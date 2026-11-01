#!/usr/bin/env bash
# 3.1 Tworzenie i zarządzanie Podami
cd "$(dirname "$0")" || exit 1

# Imperatywnie (szybkie testy)
kubectl run test-pod --image=nginx:1.29
kubectl wait --for=condition=Ready pod/test-pod
kubectl get pods
kubectl logs test-pod                          # logi kontenera (jak docker logs)
kubectl exec test-pod -- nginx -v              # polecenie w kontenerze (jak docker exec)
kubectl delete pod test-pod

# Imperatywne polecenie jako generator manifestu – dobry punkt startu do pliku YAML
kubectl create deployment web --image=nginx:1.29 --replicas=2 --dry-run=client -o yaml

# Deklaratywnie (produkcja) – Pod z manifestu YAML
kubectl apply -f pod.yaml
kubectl get pods -o wide
kubectl describe pod nginx-pod                 # na końcu sekcja Events
kubectl get pod nginx-pod -o yaml | less       # pełny obiekt: spec (pożądany) + status (aktualny)
kubectl port-forward pod/nginx-pod 8080:80     # http://localhost:8080 na jump-boksie (Ctrl+C kończy)
kubectl delete -f pod.yaml

# Deployment – zarządzanie replikami
kubectl apply -f deployment.yaml
kubectl get deploy,rs,pods
kubectl get pods --show-labels                 # pod-template-hash łączy Pody z ReplicaSetem
