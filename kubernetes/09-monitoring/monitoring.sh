#!/usr/bin/env bash
# 9. Monitorowanie i observability: metryki (Prometheus), wizualizacja (Grafana), logi (Loki + Alloy).
# Wymaga ok. 2 GB wolnej pamięci w klastrze – minikube z --memory=8192 albo usuń wcześniej Envoy Gateway (sekcja 4).
cd "$(dirname "$0")" || exit 1

# 9.1 Prometheus + Grafana (kube-prometheus-stack); values-grafana.yaml = hasło z materiałów + źródło danych Loki
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f values-grafana.yaml
kubectl -n monitoring get pods -w            # ok. minuty do Running (Ctrl+C)

# Dostęp do Grafany przez port-forward (Ctrl+C kończy); z laptopa: ssh -L 3000:localhost:3000 <użytkownik>@<jump-box>
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
# Grafana: http://localhost:3000 (admin / admin123) → Dashboards → Kubernetes / Compute Resources / Namespace (Pods)

# Prometheus: zapytania PromQL (Ctrl+C kończy) – http://localhost:9090
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
#   sum by (namespace) (rate(container_cpu_usage_seconds_total[5m]))    – CPU na namespace
#   kube_deployment_status_replicas_available{namespace="notes"}        – gotowe repliki Deploymentów
#   up                                                                  – które cele zbierania metryk działają

# 9.2 Logi – Loki + Alloy. Materiały: chart grafana/loki-stack – wycofany (Loki 2.9, Promtail bez wsparcia od 2026).
# Chart Loki utrzymuje teraz społeczność (repozytorium grafana-community); zbieraniem logów zajmuje się Grafana Alloy.
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update
helm install loki grafana-community/loki -n monitoring -f values-loki.yaml
helm install alloy grafana/alloy -n monitoring -f values-alloy.yaml
kubectl -n monitoring rollout status statefulset/loki
# Grafana → Explore → źródło Loki → zapytanie: {namespace="notes", app="notes-api"}
#   {namespace="notes"} |= "POST"                       – tylko linie z POST
#   sum by (pod) (count_over_time({namespace="notes"}[5m]))   – liczba linii logów na Pod

# ★ Własny alert: niedostępne repliki notes-api
kubectl apply -f alert-notes-api.yaml
kubectl -n notes set image deployment/notes-api api=notes-api:9.9.9   # zepsuta aktualizacja jak w sekcji 3
# Po ok. 2 min: Prometheus → Alerts – NotesApiNiedostepneRepliki: Firing; Alertmanager:
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring   # http://localhost:9093
kubectl -n notes rollout undo deployment/notes-api

# Sprzątanie (zwalnia ok. 2 GB pamięci)
# helm uninstall alloy loki monitoring -n monitoring
# kubectl delete namespace monitoring
