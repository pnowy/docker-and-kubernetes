# Sekcja 9 – Monitorowanie i observability

**Cel:** zbierać metryki klastra i aplikacji (Prometheus), oglądać je w Grafanie, przeszukiwać logi wszystkich Podów (Loki) i dostać alert, gdy aplikacja traci repliki.
**Wymaga:** klastra minikube z ok. 2 GB wolnej pamięci (`minikube start --memory=8192` albo `helm uninstall eg -n envoy-gateway-system` z sekcji 4) i `helm`; do części ★ – notes-api w namespace `notes`.

## Pliki w katalogu

| Plik                                         | Do czego                                                                     |
| -------------------------------------------- | ---------------------------------------------------------------------------- |
| [monitoring.sh](monitoring.sh)               | 9.1 kube-prometheus-stack, Grafana, PromQL; 9.2 Loki + Alloy; ★ własny alert |
| [values-grafana.yaml](values-grafana.yaml)   | hasło Grafany z materiałów i Loki jako źródło danych                         |
| [values-loki.yaml](values-loki.yaml)         | Loki w trybie monolitycznym, 1 Pod, dane na PVC                              |
| [values-alloy.yaml](values-alloy.yaml)       | Alloy: logi Podów przez API Kubernetesa → Loki, etykiety namespace/pod/app   |
| [alert-notes-api.yaml](alert-notes-api.yaml) | ★ PrometheusRule: niedostępne repliki notes-api                              |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:**

- Chart `grafana/loki-stack` z materiałów jest wycofany: instaluje Loki 2.9 i Promtail, który od 2026 r. nie dostaje poprawek. Zamiast niego: chart `loki` z repozytorium **grafana-community** (tam przeniesiono utrzymanie chartu Loki) i **Grafana Alloy** do zbierania logów.
- Hasło Grafany i źródło danych Loki są w [values-grafana.yaml](values-grafana.yaml) zamiast `--set grafana.adminPassword=…` – z pliku łatwiej powtórzyć instalację.

## Ćwiczenie 9 – metryki i logi (ok. 25 min)

1. Zainstaluj kube-prometheus-stack, otwórz Grafanę (port-forward + tunel SSH z laptopa) i znajdź dashboard **Kubernetes / Compute Resources / Namespace (Pods)** dla namespace `notes`.
2. W Prometheusie wykonaj zapytania z [monitoring.sh](monitoring.sh). Ile replik notes-api jest dostępnych?
3. Zainstaluj Loki i Alloy. W Grafanie → **Explore** → Loki wyświetl logi notes-api: `{namespace="notes", app="notes-api"}`. Wywołaj kilka razy `POST /notes` (sekcja 5) i odfiltruj te linie.
4. ★ Wgraj [alert-notes-api.yaml](alert-notes-api.yaml) i zepsuj aktualizację obrazem `notes-api:9.9.9`. Po jakim czasie alert przechodzi w stan `Firing`? Cofnij zmianę.

**Oczekiwany wynik:** Grafana ma 3 źródła danych (Prometheus, Alertmanager, Loki) i kilkanaście gotowych dashboardów Kubernetes. Zapytanie `kube_deployment_status_replicas_available{namespace="notes"}` zwraca 2. Loki zwraca linie `GET /healthz`, `GET /readyz` (sondy) i `POST /notes`. Alert jest `Pending` przez minutę (`for: 1m`), potem `Firing`; po `rollout undo` znika.

<details>
<summary><strong>Dlaczego Alloy jako Deployment, a nie DaemonSet?</strong></summary>

Klasyczni zbieracze logów (Promtail, Fluent Bit) czytają pliki z `/var/log/pods` na każdym węźle, więc działają jako DaemonSet. Komponent `loki.source.kubernetes` w Alloy pobiera logi przez API Kubernetesa (tak jak `kubectl logs`) – na małym klastrze wystarczy jeden Pod. W dużym klastrze to obciąża API Server i wtedy wybiera się DaemonSet z odczytem plików.

</details>

## Ściąga

| Polecenie                                                                                | Opis                             |
| ---------------------------------------------------------------------------------------- | -------------------------------- |
| `kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring`                      | Grafana na jump-boksie           |
| `kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring` | Prometheus                       |
| `ssh -L 3000:localhost:3000 <użytkownik>@<jump-box>`                                     | Grafana w przeglądarce laptopa   |
| `kubectl top nodes` · `kubectl top pods -A`                                              | bieżące CPU/RAM (metrics-server) |
| `{namespace="notes"} \|= "POST"`                                                         | LogQL: filtr treści logów        |
| `rate(container_cpu_usage_seconds_total[5m])`                                            | PromQL: zużycie CPU              |
| `kubectl get prometheusrules -A`                                                         | reguły alertów                   |
