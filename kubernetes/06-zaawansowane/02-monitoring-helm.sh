#!/usr/bin/env bash
# 6.1 Przykład z materiałów – stos monitorowania jako chart z repozytorium Helm.
# Instalujemy go raz, w sekcji 9 (../09-monitoring/monitoring.sh) – tu tylko oglądamy chart i jego wartości.
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo kube-prometheus-stack
helm show chart prometheus-community/kube-prometheus-stack | grep -A12 '^dependencies'   # chart składa się z innych chartów
helm show values prometheus-community/kube-prometheus-stack | grep -n 'adminPassword'      # parametr z --set w materiałach

# Polecenie z materiałów (release "prometheus"; w sekcji 9 ten sam chart instalujemy jako "monitoring"):
# helm install prometheus prometheus-community/kube-prometheus-stack \
#   --namespace monitoring --create-namespace \
#   --set grafana.adminPassword=secret
