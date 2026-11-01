#!/usr/bin/env bash
# 6.2 Zarządzanie Kubernetesem z UI

# --- Kubernetes Dashboard ---
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Utwórz token dostępu
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin
kubectl create token dashboard-admin -n kubernetes-dashboard

kubectl proxy
# Otwórz: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# --- Lens (OpenLens): https://k8slens.dev ---

# --- k9s – Terminal UI ---
# brew install k9s   # macOS
# Lub pobierz binary z: https://github.com/derailed/k9s
# k9s
