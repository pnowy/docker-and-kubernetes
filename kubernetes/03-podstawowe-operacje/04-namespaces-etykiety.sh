#!/usr/bin/env bash
# ★ Namespaces, etykiety i selektory – dodatek do sekcji 3. Wymaga nginx-deployment (01-pody-i-deploymenty.sh)

# --- Namespaces: wirtualny podział klastra ---
kubectl get namespaces
kubectl create namespace dev
kubectl create deployment web --image=nginx:1.29 -n dev
kubectl get pods -n dev
kubectl get pods -A                                    # wszystkie namespace'y
kubectl config set-context --current --namespace=dev   # domyślny namespace dla kolejnych poleceń
kubectl get pods                                       # teraz bez -n pokazuje dev
kubectl config set-context --current --namespace=default
kubectl delete namespace dev                           # usuwa namespace razem z całą zawartością

# --- Etykiety i selektory ---
kubectl apply -f pod.yaml                              # nginx-pod z etykietami app=nginx, env=dev
kubectl get pods --show-labels
kubectl label pod -l app=nginx tier=frontend           # dodaj etykietę
kubectl get pods -l app=nginx,tier=frontend            # selektor równościowy
kubectl get pods -l 'env in (dev,test)'                # selektor zbiorowy (pasuje nginx-pod z pod.yaml)
kubectl get pods -L tier                               # etykieta jako kolumna
kubectl label pod -l app=nginx tier-                   # usuń etykietę

# Pod „wyjęty” z ReplicaSetu: zmiana etykiety app odłącza go, a ReplicaSet tworzy brakującą replikę
POD=$(kubectl get pod -l app=nginx,pod-template-hash -o name | head -1)   # Pod z Deploymentu, nie nginx-pod
kubectl label "$POD" app=debug --overwrite
kubectl get pods -L app                                # 3 Pody Deploymentu + nginx-pod (app=nginx) i 1 Pod app=debug do analizy
kubectl delete "$POD"

# --- Adnotacje: metadane dla ludzi i narzędzi, nie do selekcji ---
kubectl annotate deployment nginx-deployment opis="Demo z sekcji 3"
kubectl get deployment nginx-deployment -o jsonpath='{.metadata.annotations.opis}'; echo

kubectl delete -f pod.yaml
