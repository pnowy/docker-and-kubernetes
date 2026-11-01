# Sekcja 3 – Podstawowe operacje w Kubernetesie

**Cel:** tworzyć Pody i Deploymenty imperatywnie i z YAML, skalować je ręcznie i przez HPA, aktualizować i cofać zmiany. Dodatkowo (★): namespaces, etykiety, ConfigMap, Secret, sondy, Pody z wieloma kontenerami i notes-api w klastrze.
**Wymaga:** klastra minikube z addonem `metrics-server` ([sekcja 2](../02-instalacja/README.md)).

## Pliki w katalogu

| Plik                                                                                                                  | Do czego                                                                            |
| --------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [01-pody-i-deploymenty.sh](01-pody-i-deploymenty.sh)                                                                  | 3.1: `kubectl run`, logi, exec, Pod i Deployment z YAML, `--dry-run=client -o yaml` |
| [pod.yaml](pod.yaml) · [deployment.yaml](deployment.yaml)                                                             | manifesty z materiałów (nginx 1.28, strategia RollingUpdate)                        |
| [02-skalowanie.sh](02-skalowanie.sh) · [hpa.yaml](hpa.yaml)                                                           | 3.2: `kubectl scale`, HPA i generator obciążenia                                    |
| [03-aktualizacje-rollback.sh](03-aktualizacje-rollback.sh)                                                            | 3.3: rolling update, historia, rollback, canary                                     |
| [canary/](canary/)                                                                                                    | stable (9 replik, nginx 1.28) + canary (1 replika, nginx 1.29) za jednym Serwisem   |
| [04-namespaces-etykiety.sh](04-namespaces-etykiety.sh)                                                                | ★ namespaces, etykiety, selektory, adnotacje                                        |
| [05-konfiguracja.sh](05-konfiguracja.sh) · [konfiguracja.yaml](konfiguracja.yaml)                                     | ★ ConfigMap i Secret jako zmienne i jako pliki                                      |
| [06-sondy.sh](06-sondy.sh) · [sondy.yaml](sondy.yaml)                                                                 | ★ readiness (ruch), liveness (restart), startup (wolny start)                       |
| [07-pody-wielokontenerowe.sh](07-pody-wielokontenerowe.sh) · [pody-wielokontenerowe.yaml](pody-wielokontenerowe.yaml) | ★ Pod z wieloma kontenerami, init containers, sidecar, `command`/`args`             |
| [cwiczenie-notes-api/](cwiczenie-notes-api/)                                                                          | ★ ćwiczenie: notes-api w klastrze – `start/`, `rozwiazanie/`, `rozwiazanie.sh`      |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:**

- Obrazy `nginx:1.28` → `1.29` zamiast `1.25` → `1.26` (1.25 i 1.26 nie dostają już poprawek).
- `kubectl autoscale --cpu-percent=50` działa, ale kubectl 1.37 ostrzega, że flaga jest przestarzała – nowa forma to `--cpu=50%`.
- Materiały oglądają `rollout history --revision=2` po dwóch rollbackach. Każdy rollback tworzy nową rewizję i rewizja 2 dostaje nowy numer, więc polecenie kończy się błędem `unable to find the specified revision`. W skrypcie oglądamy ją przed rollbackami.
- `--record` (dawny sposób opisu rewizji) został usunięty; opis w kolumnie `CHANGE-CAUSE` daje adnotacja `kubernetes.io/change-cause`.
- Jeden Pod `obciazenie` z busyboxem nie podnosi CPU nginx powyżej 50% – w skrypcie są 4 repliki generatora.

## Sondy ★ – startup, readiness, liveness

Każdą sondę wykonuje kubelet. Mechanizm: `httpGet` (kod 200–399), `tcpSocket` (port przyjmuje połączenie), `exec` (kod wyjścia 0) albo `grpc` (gRPC Health Checking).

| Sonda     | Kiedy działa                            | Gdy nie przechodzi                                     |
| --------- | --------------------------------------- | ------------------------------------------------------ |
| startup   | tylko na starcie, do 1. sukcesu         | po limicie restart kontenera; pozostałe sondy czekają  |
| readiness | przez całe życie kontenera              | Pod `0/1`, znika z EndpointSlice Serwisu, bez restartu |
| liveness  | przez całe życie kontenera (po startup) | kubelet restartuje kontener, `RESTARTS` rośnie         |

| Parametr              | Domyślnie | Znaczenie                                                   |
| --------------------- | --------- | ----------------------------------------------------------- |
| `initialDelaySeconds` | 0         | opóźnienie pierwszej próby od startu kontenera              |
| `periodSeconds`       | 10        | co ile sekund próba                                         |
| `timeoutSeconds`      | 1         | po ilu sekundach brak odpowiedzi to porażka                 |
| `failureThreshold`    | 3         | ile porażek z rzędu oznacza, że sonda nie przechodzi        |
| `successThreshold`    | 1         | ile sukcesów z rzędu oznacza powrót (liveness i startup: 1) |

Czas reakcji każdej sondy to ok. `failureThreshold × periodSeconds`; w startupProbe to limit czasu na start aplikacji.

**Oczekiwany wynik [06-sondy.sh](06-sondy.sh):** `sonda-readiness` ma `0/1`, dopóki nie utworzysz `/tmp/gotowe`; `sonda-liveness` ma rosnące `RESTARTS`, a potem `CrashLoopBackOff`; `sonda-startup` przez ok. 25 s ma `0/1` (`Startup probe failed: connection refused`), potem `1/1` i `RESTARTS 0`.

## Pody z wieloma kontenerami ★

Kontenery jednego Poda trafiają zawsze na ten sam węzeł, dzielą sieć (`localhost`, wspólne porty) i mogą montować te same woluminy (`emptyDir`). Polecenia `logs` i `exec` wybierają kontener przez `-c`.

| Pod                    | Co pokazuje                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| `pod-wiele-kontenerow` | nginx serwuje stronę, którą busybox co 5 s zapisuje do wspólnego `emptyDir`                         |
| `pod-init`             | dwa `initContainers` po kolei: czekanie na Serwis `baza`, potem przygotowanie pliku konfiguracji    |
| `pod-sidecar`          | sidecar (`initContainers` + `restartPolicy: Always`) czyta `access.log` nginx ze wspólnego woluminu |
| `pod-command-args`     | `command` i `args` zamiast ENTRYPOINT i CMD obrazu, rozwijanie `$(ZMIENNA)`                         |

| Kontener       | Kiedy startuje                       | Kiedy kończy                   | Typowe użycie                                 |
| -------------- | ------------------------------------ | ------------------------------ | --------------------------------------------- |
| zwykły         | po wszystkich init containers        | razem z aplikacją              | aplikacja, kilka ściśle związanych procesów   |
| init container | przed aplikacją, po kolei, jeden raz | musi się zakończyć sukcesem    | czekanie na zależność, migracja, konfiguracja |
| sidecar        | przed aplikacją, zanim ruszy kolejny | po aplikacji, działa cały czas | proxy, agent logów, odświeżanie certyfikatów  |

Natywny sidecar (init container z `restartPolicy: Always`) jest stabilny od Kubernetesa 1.33. W odróżnieniu od drugiego zwykłego kontenera startuje przed aplikacją, a w Jobie nie blokuje jego zakończenia.

| Kubernetes | Docker / Dockerfile | Uwagi                                                                   |
| ---------- | ------------------- | ----------------------------------------------------------------------- |
| `command`  | `ENTRYPOINT`        | samo `command` wyłącza też CMD obrazu                                   |
| `args`     | `CMD`               | samo `args` zostawia ENTRYPOINT obrazu i podmienia tylko jego argumenty |

`$(IMIE)` w `command`/`args` rozwija Kubernetes ze zmiennych z `env`; nieznana zmienna zostaje dosłownie (`$(NIEZNANA)`). Zmienne powłoki (`$HOSTNAME`, `$((6*7))`) wymagają `sh -c`. W `kubectl run` flaga `--command` sprawia, że wszystko po `--` trafia do `command`, a bez niej do `args`.

**Oczekiwany wynik [07-pody-wielokontenerowe.sh](07-pody-wielokontenerowe.sh):** `pod-wiele-kontenerow` i `pod-sidecar` mają `2/2`; `pod-init` stoi w `Init:0/2`, a po utworzeniu Serwisu `baza` przechodzi do `Running` i loguje `DB_HOST=baza`; `pod-command-args` ma status `Completed` i loguje `Witaj, Kubernetes! Pod: pod-command-args $(NIEZNANA)`.

## Ćwiczenie ★ – notes-api w klastrze (ok. 25 min)

Punkt startowy: [cwiczenie-notes-api/start/notes-api.yaml](cwiczenie-notes-api/start/notes-api.yaml) – minimalny Deployment. Rozwiązanie: [cwiczenie-notes-api/rozwiazanie/notes-api.yaml](cwiczenie-notes-api/rozwiazanie/notes-api.yaml) i polecenia w [cwiczenie-notes-api/rozwiazanie.sh](cwiczenie-notes-api/rozwiazanie.sh).

1. Skopiuj obraz notes-api do klastra. Obraz z części Docker jest w Dockerze jump-boxa, a minikube ma własne środowisko kontenerów:

   ```bash
   docker build -t notes-api:1.0.0 ../../app-node   # jeśli nie masz obrazu z części Docker
   docker tag notes-api:1.0.0 notes-api:1.1.0
   minikube image load notes-api:1.0.0
   minikube image load notes-api:1.1.0
   ```

2. Utwórz namespace `notes` i uzupełnij Deployment ze `start/`:
   - ConfigMap `notes-config` z `APP_VERSION=1.0.0` i `STORAGE=json` (notatki w pliku, baza dopiero w sekcji 5), podpięta przez `envFrom`;
   - `imagePullPolicy: IfNotPresent` – obrazu nie ma w żadnym rejestrze;
   - readinessProbe na `/readyz` i livenessProbe na `/healthz` (port 3000);
   - requests i limits CPU/RAM; strategia z `maxUnavailable: 0`.
3. Wdróż i sprawdź przez `kubectl -n notes port-forward deployment/notes-api 8000:3000`: `curl localhost:8000/`, dodaj notatkę `POST /notes` z polem `text`.
4. Zaktualizuj aplikację do `notes-api:1.1.0` i zmień `APP_VERSION` w ConfigMap na `1.1.0`. W jakiej kolejności to zrobić, żeby nowe Pody od razu miały nową wersję?
5. Ustaw obraz `notes-api:9.9.9` (nie istnieje). Co dzieje się z Podami i czy aplikacja nadal odpowiada? Cofnij zmianę.

**Oczekiwany wynik:** `curl localhost:8000/` zwraca `"version":"1.0.0","storage":"json"`, a po kroku 4 – `"1.1.0"`. W kroku 5 nowy Pod ma status `ImagePullBackOff`, a 2 stare Pody działają dalej (dzięki `maxUnavailable: 0` i readinessProbe), więc aplikacja odpowiada; `rollout undo` wraca do `notes-api:1.1.0`.

<details>
<summary><strong>Rozwiązanie – pytania z kroków 4 i 5</strong></summary>

4. Najpierw ConfigMap, potem obraz. Zmienne z ConfigMap Pod czyta tylko przy starcie, więc zmiana samej ConfigMap nie zmienia działających Podów – trzeba nowych Podów (`set image` albo `kubectl rollout restart`).
5. Deployment tworzy 1 nowy Pod (`maxSurge: 1`), który nie może pobrać obrazu, więc nigdy nie jest Ready. Bez gotowego nowego Poda kontroler nie usuwa starych (`maxUnavailable: 0`). `kubectl rollout status` czeka w nieskończoność – w CI ustawiaj `--timeout`. Każdy Pod ma własny plik z notatkami, więc lista notatek zależy od tego, który Pod odpowiedział – to rozwiążemy bazą w sekcji 5.

</details>

Namespace `notes` zostaw – sekcja 4 dodaje do niego Service i Ingress.

## Ściąga

| Polecenie                                                                     | Opis                                   |
| ----------------------------------------------------------------------------- | -------------------------------------- |
| `kubectl run X --image=Y`                                                     | Pod imperatywnie                       |
| `kubectl create deployment X --image=Y --dry-run=client -o yaml`              | szkielet manifestu                     |
| `kubectl apply -f plik.yaml` · `delete -f plik.yaml`                          | utwórz/zaktualizuj, usuń z pliku       |
| `kubectl get pods -o wide` · `--show-labels` · `-L etykieta`                  | lista z węzłem, z etykietami           |
| `kubectl describe pod X` · `logs X` · `exec X -- polecenie`                   | szczegóły i zdarzenia, logi, polecenie |
| `kubectl port-forward pod/X 8080:80`                                          | port Poda na jump-boksie               |
| `kubectl scale deployment X --replicas=5`                                     | ręczne skalowanie                      |
| `kubectl autoscale deployment X --cpu=50% --min=2 --max=10`                   | HPA                                    |
| `kubectl set image deployment/X kontener=obraz:tag`                           | rolling update                         |
| `kubectl rollout status` · `history` · `undo [--to-revision=N]`               | przebieg, historia, rollback           |
| `kubectl rollout restart deployment/X`                                        | nowe Pody bez zmiany obrazu            |
| `kubectl create configmap X --from-literal=K=V`                               | ConfigMap                              |
| `kubectl create secret generic X --from-literal=K=V`                          | Secret (base64, nie szyfrowanie)       |
| `kubectl config set-context --current --namespace=X`                          | domyślny namespace                     |
| `kubectl describe pod X \| grep -E 'Startup\|Readiness\|Liveness\|Unhealthy'` | sondy i ich porażki                    |
| `kubectl logs X --previous`                                                   | logi kontenera sprzed restartu         |
