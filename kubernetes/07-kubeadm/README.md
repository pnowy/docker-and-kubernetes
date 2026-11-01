# Sekcja 7 – Klaster kubeadm na maszynach wirtualnych

**Cel:** postawić pełny klaster Kubernetes (1 Control Plane + 2 workery) narzędziem kubeadm i zarządzać nim z jump-boxa obok minikube.
**Wymaga:** 3 maszyn wirtualnych Ubuntu 22.04/24.04 (2 CPU, 2 GB RAM, unikalne nazwy hostów, widoczność w sieci) i jump-boxa z dostępem SSH do nich. Adresy i użytkownika podaje prowadzący.

```text
jump-box (minikube, kubectl, ssh)
   ├── cp       – Control Plane: kubeadm init, etcd, API Server, Calico
   ├── worker1  – kubeadm join
   └── worker2  – kubeadm join
```

## Pliki w katalogu

| Plik                                               | Gdzie uruchamiasz | Do czego                                                       |
| -------------------------------------------------- | ----------------- | -------------------------------------------------------------- |
| [z-jump-boxa.sh](z-jump-boxa.sh)                   | jump-box          | cały przebieg: kopia skryptów, kroki 1–4 przez SSH, kubeconfig |
| [common.sh](common.sh)                             | każda VM          | swap, moduły jądra, containerd, kubeadm/kubelet/kubectl        |
| [install_master.sh](install_master.sh)             | cp                | krok 1 i 3: `kubeadm init`, kubeconfig, polecenie join, Calico |
| [install_worker_nodes.sh](install_worker_nodes.sh) | worker1, worker2  | krok 2: przygotowanie węzła przed `kubeadm join`               |
| [deploy_nginx.sh](deploy_nginx.sh)                 | cp                | krok 4: testowy nginx z Serwisem NodePort                      |

**Status:** skrypty sprawdzone na Ubuntu 24.04 do poziomu pakietów (repozytoria, wersje containerd 2.x i kubeadm 1.37). Pełny przebieg `kubeadm init/join` trzeba przetestować na docelowych maszynach przed zajęciami.

## Poprawki względem materiałów ALX

Materiały w punkcie 7.1 opisują trzy błędy w skryptach – w tym katalogu są już poprawione:

| Problem z materiałów                      | Poprawka w skryptach                                       |
| ----------------------------------------- | ---------------------------------------------------------- |
| Błąd 1: brak katalogu `/etc/apt/keyrings` | `sudo mkdir -p /etc/apt/keyrings` w [common.sh](common.sh) |
| Błąd 2: zapis klucza GPG bez `sudo`       | `curl … \| gpg --dearmor \| sudo tee …`                    |
| Błąd 3: Calico z manifestu v3.25.0        | operator Tigera, Calico v3.33.0 (materiały: v3.28.0)       |
| `deploy_nginx.sh` nie czeka na Pody       | `kubectl rollout status` przed listą Podów                 |

Dodatkowe zmiany:

- **Pula adresów Podów 10.244.0.0/16** zamiast domyślnej 192.168.0.0/16 Calico. Sieci maszyn wirtualnych to często 192.168.x.0/24 – gdy pula Podów na nie nachodzi, węzły tracą łączność. Skrypt podmienia `cidr` w `custom-resources.yaml`; inną pulę ustawisz zmienną `POD_CIDR`.
- **Calico z enkapsulacją VXLAN** zamiast domyślnej `VXLANCrossSubnet`. W jednej podsieci `VXLANCrossSubnet` wysyła pakiety Podów bez enkapsulacji, a sieć chmury (np. Azure) nie zna adresów Podów i je odrzuca. Inną wartość ustawisz zmienną `CALICO_ENCAPSULATION`.
- **containerd 2.x z repozytorium Dockera** (`containerd.io`) zamiast pakietu `containerd` z Ubuntu (1.7) – starsza gałąź jest na granicy wsparcia aktualnego kubeleta.
- Kubernetes 1.37 (`K8S_MINOR=v1.37`) zamiast wersji z materiałów.

## Ćwiczenie 7 – klaster kubeadm (ok. 45 min)

Wykonaj [z-jump-boxa.sh](z-jump-boxa.sh) krok po kroku na jump-boksie – najpierw sprawdź w nim adresy maszyn (`CP`, `WORKERS`) i użytkownika (`U`). Cały przebieg jednym poleceniem: `../../srodowisko/tools-setup-automated.sh ssh kubeadm kubeconfig` ([srodowisko/](../../srodowisko/)). Ten sam przebieg ręcznie, jak w materiałach:

1. **Krok 1** – na `cp`: `./install_master.sh`. Na końcu skrypt zapisuje polecenie `kubeadm join` w pliku `info_join_worker` i instaluje Calico.
2. **Krok 2** – na każdym workerze: `./install_worker_nodes.sh`, a potem `sudo kubeadm join …` z pliku `info_join_worker`.
3. **Krok 3** – na `cp`: `kubectl get nodes -w` – węzły przechodzą w `Ready`, gdy Calico wystartuje na każdym z nich.
4. **Krok 4** – na `cp`: `./deploy_nginx.sh`, potem `curl http://<IP_węzła>:<NodePort>`.
5. Skopiuj kubeconfig na jump-box i dodaj kontekst `kubeadm` obok `minikube` (polecenia w skrypcie).

Skrypty opisują każdy etap (`▶` co robią, `✓` co się stało – z wersją containerd, kubeadm, kubeleta) i zatrzymują się na 1 s po każdym. `PAUZA=3 ./install_master.sh` wydłuża przerwę na pokaz, `PAUZA=0` ją wyłącza.

**Oczekiwany wynik:** `kubectl --context kubeadm get nodes` pokazuje 3 węzły `Ready` (`cp` z rolą `control-plane`), Pody `calico-node` działają na każdym węźle, a `curl` na NodePort zwraca `HTTP/1.1 200 OK` z adresu **każdego** węzła – także tego, na którym nie działa żaden Pod nginx.

<details>
<summary><strong>Najczęstsze problemy</strong></summary>

| Objaw                                        | Przyczyna i rozwiązanie                                                            |
| -------------------------------------------- | ---------------------------------------------------------------------------------- |
| `kubeadm init`: `[ERROR Swap]`               | swap włączony – `sudo swapoff -a` (robi to `common.sh`)                            |
| `kubeadm join`: `token … invalid` lub wygasł | token ważny 24 h – na `cp`: `sudo kubeadm token create --print-join-command`       |
| węzły `NotReady` po kilku minutach           | Calico nie wstało: `kubectl get pods -n calico-system`, `kubectl get tigerastatus` |
| Pody na różnych węzłach się nie widzą        | zapora między VM – VXLAN potrzebuje UDP 4789; tryb: `kubectl get ippools -o yaml`  |
| dwa węzły o tej samej nazwie                 | sklonowane VM – `sudo hostnamectl set-hostname worker2` przed `kubeadm join`       |

Sprzątanie (workery, potem `cp`): `sudo kubeadm reset -f && sudo rm -rf /etc/cni/net.d ~/.kube`.

</details>

## Ściąga

| Polecenie                                                                | Opis                            |
| ------------------------------------------------------------------------ | ------------------------------- |
| `sudo kubeadm init --pod-network-cidr=…`                                 | inicjalizacja Control Plane     |
| `sudo kubeadm token create --print-join-command`                         | nowe polecenie dołączenia węzła |
| `sudo kubeadm join <IP>:6443 --token … --discovery-token-ca-cert-hash …` | dołączenie workera              |
| `sudo kubeadm reset -f`                                                  | wycofanie węzła z klastra       |
| `kubectl --context kubeadm get nodes`                                    | klaster kubeadm z jump-boxa     |
| `kubectl config use-context kubeadm` · `minikube`                        | przełączanie klastrów           |
| `systemctl status kubelet` · `journalctl -u kubelet -f`                  | diagnostyka węzła               |
