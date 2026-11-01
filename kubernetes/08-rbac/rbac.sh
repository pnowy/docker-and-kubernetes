#!/usr/bin/env bash
# 8.2 RBAC – tylko odczyt Podów w namespace testowa
cd "$(dirname "$0")" || exit 1

# Manifest zawiera też Namespace i ServiceAccount, których nie ma w materiałach
kubectl apply -f rbac-pod-reader.yaml

# Weryfikacja uprawnień
kubectl auth can-i list pods --as=system:serviceaccount:testowa:monitoring-agent -n testowa          # yes
kubectl auth can-i delete deployments --as=system:serviceaccount:testowa:monitoring-agent -n testowa # no
kubectl auth can-i list pods --as=system:serviceaccount:testowa:monitoring-agent -n default          # no – Role działa tylko w swoim namespace
kubectl auth can-i --list --as=system:serviceaccount:testowa:monitoring-agent -n testowa             # wszystkie uprawnienia konta

# ★ To samo z prawdziwym tokenem: Pod na koncie monitoring-agent. Obraz registry.k8s.io/kubectl
# ma tylko kubectl (bez powłoki), więc każde polecenie to osobny, krótki Pod; kubectl w Podzie
# sam znajduje API Server i token konta zamontowany w /var/run/secrets/kubernetes.io/serviceaccount
AGENT='{"spec":{"serviceAccountName":"monitoring-agent"}}'
kubectl -n testowa run agent --image=registry.k8s.io/kubectl:v1.37.0 --overrides="$AGENT" --rm -i --restart=Never -- get pods      # działa
kubectl -n testowa run agent --image=registry.k8s.io/kubectl:v1.37.0 --overrides="$AGENT" --rm -i --restart=Never -- get secrets   # Forbidden

# ★ Wbudowane ClusterRole: view, edit, admin, cluster-admin
kubectl get clusterroles view edit admin cluster-admin
kubectl describe clusterrole view | head -20
# RoleBinding do ClusterRole: uprawnienia "view", ale tylko w namespace testowa
kubectl -n testowa create rolebinding agent-view --clusterrole=view --serviceaccount=testowa:monitoring-agent
kubectl -n testowa run agent --image=registry.k8s.io/kubectl:v1.37.0 --overrides="$AGENT" --rm -i --restart=Never -- get deployments,services   # teraz działa
kubectl auth can-i list pods --as=system:serviceaccount:testowa:monitoring-agent -n default   # nadal no

# ★ Krótkotrwały token konta (np. dla CI) – ważny godzinę
kubectl -n testowa create token monitoring-agent --duration=1h | cut -c1-40

# Sprzątanie
kubectl delete namespace testowa
