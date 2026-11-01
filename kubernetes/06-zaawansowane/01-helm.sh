#!/usr/bin/env bash
# 6.1 Helm: zarządzanie aplikacjami w Kubernetes
cd "$(dirname "$0")" || exit 1

# Instalacja Helm 4 (macOS: brew install helm). Materiały: skrypt get-helm-3 – Helm 3 dostaje już tylko poprawki
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
helm version

# Podstawowe polecenia Helm. Materiały używają bitnami/nginx – Bitnami od 2025 nie publikuje darmowych,
# aktualizowanych obrazów, dlatego ćwiczymy na charcie podinfo (rejestr OCI, bez helm repo add)
helm show chart oci://ghcr.io/stefanprodan/charts/podinfo --version 6.17.0
helm show values oci://ghcr.io/stefanprodan/charts/podinfo --version 6.17.0 | less   # podgląd parametrów

helm install moj-podinfo oci://ghcr.io/stefanprodan/charts/podinfo --version 6.17.0 \
  --set replicaCount=2 \
  --set service.type=NodePort

helm list                         # lista release'ów
helm status moj-podinfo
kubectl get deploy,svc moj-podinfo
helm upgrade moj-podinfo oci://ghcr.io/stefanprodan/charts/podinfo --version 6.17.0 --reuse-values --set replicaCount=3
helm history moj-podinfo
helm rollback moj-podinfo 1       # cofnij do rewizji 1 (2 repliki)
helm get values moj-podinfo       # wartości ustawione przez nas (--set)
helm uninstall moj-podinfo

# Repozytorium HTTP (klasyczny sposób z materiałów) – ten sam mechanizm, inne źródło chartów
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm search repo podinfo

# Tworzenie własnego Chartu
helm create moja-aplikacja
# Tworzy strukturę:
# moja-aplikacja/
#   Chart.yaml      - metadane Chartu
#   values.yaml     - domyślne wartości
#   templates/      - szablony YAML
#     deployment.yaml
#     service.yaml
#     ingress.yaml

# Zweryfikuj szablony przed instalacją
helm template moja-aplikacja ./moja-aplikacja -f custom-values.yaml | less
helm lint ./moja-aplikacja
helm install moja-aplikacja ./moja-aplikacja -f custom-values.yaml
kubectl get deploy,svc -l app.kubernetes.io/instance=moja-aplikacja

# Sprzątanie
helm uninstall moja-aplikacja
rm -rf moja-aplikacja
