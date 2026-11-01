#!/usr/bin/env bash
# 5.2 StorageClass i dynamiczne PV. Dodatkowo (★) własna klasa z reclaimPolicy: Retain.
cd "$(dirname "$0")" || exit 1

kubectl get storageclass                     # standard (default) – provisioner k8s.io/minikube-hostpath
kubectl describe storageclass standard

# ★ Własna klasa: PV zostaje po usunięciu PVC (Retain zamiast Delete)
kubectl apply -f storageclass-minikube.yaml
kubectl get pvc pvc-zachowaj                 # Bound – volumeBindingMode: Immediate, PV powstał od razu
kubectl get pv                               # PV o nazwie pvc-<uid>, CLAIM: default/pvc-zachowaj
kubectl delete pvc pvc-zachowaj
kubectl get pv                               # STATUS: Released – dane zostały, PV nie przyjmie nowego PVC bez sprzątania
kubectl delete pv "$(kubectl get pv -o jsonpath='{.items[?(@.spec.storageClassName=="zachowaj")].metadata.name}')"
kubectl delete storageclass zachowaj

# Klasa z materiałów (storageclass-aws.yaml) wymaga AWS EKS – na minikube PVC zostałby Pending
