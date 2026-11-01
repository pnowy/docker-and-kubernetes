#!/usr/bin/env bash
# 6.2 Zarządzanie Kubernetesem z UI.
# Materiały instalują Kubernetes Dashboard v2.7.0 – projekt został wycofany (repozytorium zarchiwizowane, brak poprawek).
# Jego następcą w ramach SIG UI jest Headlamp.

# --- Headlamp (addon minikube, włączony w sekcji 2) ---
minikube addons enable headlamp
kubectl -n headlamp rollout status deploy/headlamp
kubectl -n headlamp create token headlamp --duration 24h   # token do logowania (konto z uprawnieniami cluster-admin)
kubectl -n headlamp port-forward svc/headlamp 8080:80      # http://localhost:8080 (Ctrl+C kończy)
# Z laptopa: ssh -L 8080:localhost:8080 <użytkownik>@<jump-box>
# Bez addonu (inne klastry, np. kubeadm z sekcji 7):
#   helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
#   helm install headlamp headlamp/headlamp -n kube-system

# --- k9s – Terminal UI (działa w sesji SSH na jump-boksie) ---
# Linux: pobierz binarkę z https://github.com/derailed/k9s/releases  ·  macOS: brew install k9s
k9s
# :pods, :deploy, :svc – widoki;  / – filtr;  l – logi;  s – shell;  d – describe;  Ctrl+D – usuń;  :q – wyjście

# --- Lens / Freelens (aplikacja desktopowa, na laptopie) ---
# https://k8slens.dev  ·  https://freelensapp.github.io (otwarty fork OpenLens)
# Na laptopie potrzebny kubeconfig i dostęp do API Servera – przy minikube na jump-boksie: Headlamp lub k9s są prostsze.
