# Docker i Kubernetes – materiały dla uczestników

Szkolenie ALX Docker + Kubernetes (3 dni). Repozytorium zawiera wszystko, czego potrzebujesz na zajęciach i po nich.

## Od czego zacząć

Na szkoleniu każdy pracuje na **własnym jump-boksie** – maszynie wirtualnej z Ubuntu 24.04 przygotowanej na zajęcia, a nie na swoim komputerze. Dzięki temu wszyscy mają to samo środowisko i każdy wykonuje ćwiczenia krok po kroku samodzielnie. Adres, użytkownika i hasło podaje prowadzący.

1. Zaloguj się na jump-box (`ssh kurs@<IP_jump-boxa>` albo RDP) i pobierz materiały:

   ```bash
   sudo apt-get update
   sudo apt-get install -y git
   git clone https://github.com/pnowy/docker-and-kubernetes
   cd docker-and-kubernetes
   ```

2. Przygotuj jump-box według [srodowisko/](srodowisko/): polecenie po poleceniu (`tools-setup-manual.sh`) albo automatycznie (`tools-setup-automated.sh`) – powłoka, Docker, narzędzia Kubernetes i minikube. Tam też konfiguracja SSH i VS Code, żeby wygodnie pracować na jump-boksie z laptopa.
3. Sprawdź instalację: `docker run --rm hello-world` powinno wypisać `Hello from Docker!`.
4. Pobierz obrazy używane w pierwszych rozdziałach, żeby nie czekać na nie w trakcie ćwiczeń:

   ```bash
   for i in hello-world ubuntu ubuntu:20.04 mariadb mariadb:10.6 mariadb:11.8 busybox busybox:1.37 nginx:1.29 node:24 node:24-slim postgres:18 python:3.12-slim; do docker pull $i; done
   ```

Po szkoleniu ćwiczenia możesz powtórzyć na własnym komputerze: Docker Desktop (macOS/Windows) albo Docker Engine na Ubuntu – instrukcje w [docker/02-instalacja/](docker/02-instalacja/).

## Materiały PDF

| Plik                                                                           | Zawartość                  |
| ------------------------------------------------------------------------------ | -------------------------- |
| [materials/docker-presentation.pdf](materials/docker-presentation.pdf)         | slajdy z części Docker     |
| [materials/kubernetes-presentation.pdf](materials/kubernetes-presentation.pdf) | slajdy z części Kubernetes |

## Wymagania

- Laptop z klientem SSH (albo RDP) i przeglądarką – całe oprogramowanie instalujemy na jump-boksie
- Jump-box (Ubuntu 24.04) z Dockerem i pluginem `docker compose`, a do części Kubernetes z `minikube`, `kubectl` i `helm` – przygotowanie w [srodowisko/](srodowisko/)
- Rozdział Kubernetes 7 (kubeadm): 3 maszyny wirtualne Ubuntu 22.04/24.04 (2 CPU, 2 GB RAM każda), dostępne z jump-boxa po SSH – przygotowanie: `srodowisko/tools-setup-automated.sh ssh kubeadm kubeconfig`

## Aplikacja przewodnia: notes-api

[app-node/](app-node/) – proste API notatek w Node.js 24 + TypeScript (Express 5) z bazą PostgreSQL 18, używane w częściach Docker i Kubernetes.

| Plik                                            | Zawartość                                                               |
| ----------------------------------------------- | ----------------------------------------------------------------------- |
| [src/server.ts](app-node/src/server.ts)         | API: `/`, `/healthz`, `/readyz`, `GET/POST /notes`                      |
| [Dockerfile.simple](app-node/Dockerfile.simple) | pierwsza, naiwna wersja obrazu (1,2 GB), celowo zła kolejność dla cache |
| [Dockerfile.cached](app-node/Dockerfile.cached) | jak simple, ale zależności przed kodem – npm ci z cache                 |
| [Dockerfile](app-node/Dockerfile)               | multi-stage: etapy deps, build, dev, runtime (250 MB, użytkownik node)  |
| [compose.yaml](app-node/compose.yaml)           | API + PostgreSQL: .env, sekret, healthcheck, profil `narzedzia`         |
| [compose.dev.yaml](app-node/compose.dev.yaml)   | development z `docker compose watch`                                    |
| [compose.prod.yaml](app-node/compose.prod.yaml) | nadpisanie na serwer: obraz z rejestru, limity, logi, sieć `internal`   |

```bash
cd app-node
docker compose up -d --build --wait
curl http://localhost:8000/notes
```

Bez Dockera (Node.js 24 na komputerze): `npm ci && npm run dev-json` – notatki w pliku `data/notes.json`, bez bazy, restart po każdej zmianie w `src/`; `npm run dev` oczekuje działającego PostgreSQL.

[app-python/](app-python/) – ta sama aplikacja w Pythonie 3.12 + FastAPI z bazą MariaDB (port 8000, `STORAGE=mariadb|json`): alternatywa w labie z sekcji 4, lab Compose w sekcji 8 ([compose.yaml](app-python/compose.yaml)) i przykład multi-stage w sekcji 10. Opis w [app-python/README.md](app-python/README.md).

## Docker

| Sekcja                     | Katalog                                                           | Zawartość                                                                                                        |
| -------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| 1. Wprowadzenie            | [docker/01-wprowadzenie](docker/01-wprowadzenie/)                 | Teoria: VM a kontener, historia kontenerów, architektura Dockera, pytania kontrolne                              |
| 2. Instalacja na Ubuntu    | [docker/02-instalacja](docker/02-instalacja/)                     | Instalacja z repozytorium apt lub get.docker.com; 2A: sprawdzenie środowiska; 2B: kontener to proces             |
| 3. Zarządzanie obrazami    | [docker/03-obrazy](docker/03-obrazy/)                             | search, pull, images, inspect, history, tag, push, rmi; warstwy i copy-on-write                                  |
| 4. Dockerfile              | [docker/04-dockerfile](docker/04-dockerfile/)                     | Obraz Apache na Ubuntu 20.04, lab: konteneryzacja notes-api; dodatkowo ENTRYPOINT vs CMD                         |
| 5. Zarządzanie kontenerami | [docker/05-kontenery](docker/05-kontenery/)                       | run, ps, stop/start, logs, exec, cp, inspect; dodatkowo restart, limity, logi                                    |
| 6. Woluminy                | [docker/06-woluminy](docker/06-woluminy/)                         | Named volume, bind mount, `--mount`, tmpfs; dodatkowo kopia zapasowa, NFS                                        |
| 7. Sieci                   | [docker/07-sieci](docker/07-sieci/)                               | Sterowniki sieci, sieć użytkownika, DNS po nazwach, connect/disconnect                                           |
| 8. Docker Compose          | [docker/08-compose](docker/08-compose/)                           | Apache + MariaDB, podstawowe polecenia; lab: notes-api w Pythonie + MariaDB                                      |
| 9. Ćwiczenia praktyczne    | [docker/09-cwiczenia](docker/09-cwiczenia/)                       | Ćwiczenia I–V z rozwiązaniami                                                                                    |
| 10. Multi-stage builds     | [docker/10-multi-stage](docker/10-multi-stage/)                   | Python/FastAPI, notes-api 1,2 GB → 250 MB; dodatkowo obrazy bazowe, build secrets, multi-platform, Java          |
| 11. Bezpieczeństwo         | [docker/11-bezpieczenstwo](docker/11-bezpieczenstwo/)             | Non-root, hardening runtime, capabilities, skanowanie podatności, SBOM                                           |
| 12. Optymalizacja          | [docker/12-optymalizacja](docker/12-optymalizacja/)               | Kolejność instrukcji i cache buildera, `docker history`, `dive`, `docker system df`                              |
| 13. Compose – zaawansowane | [docker/13-compose-zaawansowane](docker/13-compose-zaawansowane/) | `.env`, nadpisywanie plików, healthcheck; dodatkowo sekrety, profile, watch, Compose na serwerze, load balancing |
| 14. Prywatny rejestr       | [docker/14-rejestr](docker/14-rejestr/)                           | registry:2, push/pull; dodatkowo tagi i etykiety OCI, podpisy cosign, workflow GitHub Actions                    |
| 15. Troubleshooting        | [docker/15-troubleshooting](docker/15-troubleshooting/)           | Odtworzenie typowych problemów i ich rozwiązania                                                                 |
| 16. AI (dodatek)           | [docker/16-ai](docker/16-ai/)                                     | Prompt, Dockerfile wygenerowany przez AI, checklista weryfikacji                                                 |

Kolejność ma znaczenie: obraz `moj-apache:1.0` (oraz tag `ubuntu_apache`) buduje [docker/04-dockerfile/build.sh](docker/04-dockerfile/build.sh) – korzystają z niego sekcje 5, 6, 8, 14 i ćwiczenie IV. Obraz `notes-api:1.0.0` (multi-stage) buduje `docker build -t notes-api:1.0.0 .` w [app-node/](app-node/) w sekcji 10 – korzystają z niego sekcje 11, 13, 14 i 15.

## Kubernetes

Katalogi `kubernetes/01-…` – `kubernetes/10-…` mają te same numery co sekcje materiałów ALX (sekcja 11 to dodatek). Tematy spoza materiałów są w README oznaczone ★. Wszystkie ćwiczenia poza sekcją 7 robimy na klastrze **minikube** na jump-boksie:

```bash
minikube start --driver=docker --cni=calico --cpus=4 --memory=8192
minikube addons enable metrics-server
minikube addons enable ingress
minikube addons enable headlamp
```

| Rozdział               | Katalog                                                                 | Zawartość                                                                                |
| ---------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| 1. Wprowadzenie        | [kubernetes/01-wprowadzenie](kubernetes/01-wprowadzenie/)               | architektura na żywym klastrze, przepływ tworzenia Poda, samonaprawianie                 |
| 2. Instalacja          | [kubernetes/02-instalacja](kubernetes/02-instalacja/)                   | minikube (klaster szkolenia), kind, k3s, klaster laboratoryjny kind                      |
| 3. Podstawowe operacje | [kubernetes/03-podstawowe-operacje](kubernetes/03-podstawowe-operacje/) | Pod, Deployment, HPA, rollout, canary; ★ namespaces, ConfigMap, Secret, sondy, notes-api |
| 4. Networking          | [kubernetes/04-networking](kubernetes/04-networking/)                   | Service, Ingress, NetworkPolicy; ★ Gateway API, notes-api za Ingressem                   |
| 5. Storage             | [kubernetes/05-storage](kubernetes/05-storage/)                         | PV, PVC, StorageClass, StatefulSet; ★ Job, CronJob, notes-api z PostgreSQL               |
| 6. Zaawansowane        | [kubernetes/06-zaawansowane](kubernetes/06-zaawansowane/)               | Helm, Headlamp, k9s, CRD; ★ własny chart notes-api                                       |
| 7. kubeadm na VM       | [kubernetes/07-kubeadm](kubernetes/07-kubeadm/)                         | 1 Control Plane + 2 workery, sterowane z jump-boxa                                       |
| 8. RBAC                | [kubernetes/08-rbac](kubernetes/08-rbac/)                               | Role, RoleBinding, `auth can-i`; ★ konto dla CI                                          |
| 9. Monitoring          | [kubernetes/09-monitoring](kubernetes/09-monitoring/)                   | kube-prometheus-stack, Grafana, Loki + Alloy; ★ własny alert                             |
| 10. Troubleshooting    | [kubernetes/10-troubleshooting](kubernetes/10-troubleshooting/)         | diagnostyka Podów, węzłów i sieci; ★ sześć zepsutych aplikacji                           |
| 11. AI (dodatek)       | [kubernetes/11-ai](kubernetes/11-ai/)                                   | manifest od AI z błędami, checklista, kubeconform, kube-linter, k8sgpt                   |

Ćwiczenia ★ z notes-api budują jedną aplikację w namespace `notes`: sekcja 3 (Deployment, ConfigMap, sondy) → 4 (Service, Ingress, NetworkPolicy) → 5 (PostgreSQL, Secret) → 6 (chart Helm), 8 (RBAC), 9 (monitoring), 11 (AI). Rób je po kolei – każde korzysta z poprzedniego.

## Uwagi o projektach upstream

- **ingress-nginx** (addon `ingress` w minikube) zakończył rozwój w marcu 2026 r. Używamy go, bo dotyczą go materiały ALX; w nowych projektach wybierz Gateway API (sekcja 4 ★).
- **Bitnami** od 2025 r. nie publikuje darmowych, aktualizowanych obrazów – zamiast `bitnami/nginx` ćwiczymy Helm na charcie podinfo.
- **Kubernetes Dashboard** i chart `grafana/loki-stack` są wycofane – zamiast nich Headlamp oraz Loki z repozytorium grafana-community i Grafana Alloy.
