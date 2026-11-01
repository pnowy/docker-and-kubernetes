# Sekcja 6 – Zaawansowane tematy

**Cel:** instalować i aktualizować aplikacje Helmem, napisać własny chart, zarządzać klastrem z UI i rozszerzyć API o własny typ zasobu (CRD).
**Wymaga:** klastra minikube z addonami `ingress` i `headlamp` ([sekcja 2](../02-instalacja/README.md)) oraz `helm` 4; do ćwiczenia ★ – obrazu `notes-api:1.1.0` w minikube ([sekcja 3](../03-podstawowe-operacje/README.md)).

## Pliki w katalogu

| Plik                                                                                          | Do czego                                                                   |
| --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [01-helm.sh](01-helm.sh)                                                                      | 6.1: install, upgrade, history, rollback na charcie podinfo; `helm create` |
| [custom-values.yaml](custom-values.yaml)                                                      | 6.1: wartości dla chartu z `helm create moja-aplikacja`                    |
| [02-monitoring-helm.sh](02-monitoring-helm.sh)                                                | 6.1: chart kube-prometheus-stack – oglądamy tu, instalujemy w sekcji 9     |
| [03-ui.sh](03-ui.sh)                                                                          | 6.2: Headlamp, k9s, Lens                                                   |
| [04-crd.sh](04-crd.sh)                                                                        | ćwiczenie 6.3 (kroki 32–35): własny typ zasobu MojaAplikacja               |
| [crd-mojaaplikacja.yaml](crd-mojaaplikacja.yaml) · [moja-instancja.yaml](moja-instancja.yaml) | CRD z walidacją `replicas >= 1` i jego instancja                           |
| [05-aliasy.sh](05-aliasy.sh)                                                                  | aliasy kubectl i przełączanie kontekstów                                   |
| [notes-api-chart/](notes-api-chart/)                                                          | ★ własny chart notes-api: ConfigMap, Deployment, Service, Ingress          |
| [06-notes-api-helm.sh](06-notes-api-helm.sh)                                                  | ★ ćwiczenie: dwa środowiska z jednego chartu, upgrade, rollback            |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:**

- Helm 4 (skrypt `get-helm-4`) zamiast Helm 3. Polecenia z materiałów działają bez zmian.
- Chart `bitnami/nginx` zastąpiony chartem **podinfo** z rejestru OCI: Bitnami od 2025 r. nie publikuje darmowych, aktualizowanych obrazów, a stare obrazy przeniesiono do `bitnamilegacy`. Mechanizm (`install`, `--set`, `upgrade`, `rollback`) jest ten sam.
- Kubernetes Dashboard (v2.7.0 w materiałach) został wycofany – repozytorium jest zarchiwizowane i nie dostaje poprawek. Zamiast niego używamy **Headlamp** (projekt Kubernetes SIG UI, addon minikube). OpenLens nie jest już rozwijany; otwarty fork to Freelens.

## Ćwiczenie 6.3 – własny zasób CRD (ok. 10 min)

Wykonaj kroki 32–35 z [04-crd.sh](04-crd.sh).

**Oczekiwany wynik:** `kubectl get crd` pokazuje `mojeaplikacje.example.com`; `kubectl get ma` – obiekt `pierwsza-aplikacja`; próba ustawienia `replicas: 0` kończy się błędem `should be greater than or equal to 1`. Żaden Pod nie powstaje – CRD dodaje tylko typ danych, a działanie dodaje dopiero kontroler (operator).

## Ćwiczenie ★ – chart notes-api (ok. 20 min)

Chart: [notes-api-chart/](notes-api-chart/), polecenia: [06-notes-api-helm.sh](06-notes-api-helm.sh).

1. Obejrzyj [values.yaml](notes-api-chart/values.yaml) i szablony w [templates/](notes-api-chart/templates/). Które wartości trafiają do ConfigMap, a które do Deploymentu?
2. Wyrenderuj chart (`helm template`) z `--set storage=postgres` – co dochodzi do ConfigMap i Deploymentu?
3. Zainstaluj chart dwa razy: `notes` w namespace `notes-helm` i `notes-staging` z [values-staging.yaml](notes-api-chart/values-staging.yaml).
4. Zwiększ liczbę replik przez `helm upgrade`, obejrzyj historię i cofnij zmianę.

**Oczekiwany wynik:** `helm list -A` pokazuje oba release'y; `curl -H "Host: notes-helm.local" http://$(minikube ip)/` zwraca JSON notes-api. Z `storage=postgres` ConfigMap dostaje zmienne `PG*`, a Deployment – wolumin z Secretem `notes-db`. Po `helm rollback notes 1` znów działają 2 repliki.

<details>
<summary><strong>Po co adnotacja <code>checksum/config</code> w Deploymencie?</strong></summary>

Zmiana samej ConfigMap nie restartuje Podów (sekcja 3). Suma kontrolna treści ConfigMap jest częścią szablonu Poda, więc każda zmiana wartości w ConfigMap zmienia szablon – a to uruchamia rolling update przy `helm upgrade`.

</details>

## Ściąga

| Polecenie                                                                 | Opis                            |
| ------------------------------------------------------------------------- | ------------------------------- |
| `helm repo add X URL` · `helm repo update` · `helm search repo X`         | repozytoria chartów             |
| `helm show values CHART`                                                  | domyślne wartości chartu        |
| `helm install REL CHART [-n NS --create-namespace] [-f plik] [--set k=v]` | instalacja                      |
| `helm upgrade REL CHART [--reuse-values]` · `helm rollback REL N`         | aktualizacja, powrót do rewizji |
| `helm list -A` · `helm status REL` · `helm history REL`                   | release'y i ich historia        |
| `helm get values REL` · `helm get manifest REL`                           | co zostało zainstalowane        |
| `helm create X` · `helm lint X` · `helm template REL X`                   | własny chart                    |
| `helm uninstall REL`                                                      | usunięcie release'u             |
| `kubectl get crd` · `kubectl explain TYP.spec`                            | własne typy zasobów             |
| `k9s`                                                                     | UI w terminalu                  |
