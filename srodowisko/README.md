# Środowisko szkolenia – jump-box i maszyny kubeadm

**Cel:** przygotować jump-box do całego szkolenia – polecenie po poleceniu albo jednym skryptem – i wygodnie pracować na nim z własnego komputera (SSH, VS Code).
**Wymaga:** dostępu do jump-boxa (Ubuntu 24.04) po SSH lub RDP. Adresy, użytkownika i hasło podaje prowadzący.

```text
laptop ──ssh/RDP──▶ jump-box 10.4.0.10 (XFCE, Docker, minikube, kubectl)
                       ├──ssh──▶ k8s-cp       10.4.0.50   Control Plane (sekcja Kubernetes 7)
                       ├──ssh──▶ k8s-worker1  10.4.0.100  worker
                       └──ssh──▶ k8s-worker2  10.4.0.200  worker
```

Maszyny kubeadm są dostępne **tylko z jump-boxa** – z laptopa łączysz się do nich przez jump-box (`ProxyJump`, niżej).

## Pliki w katalogu

| Plik                                                 | Do czego                                                                 |
| ---------------------------------------------------- | ------------------------------------------------------------------------ |
| [tools-setup-manual.sh](tools-setup-manual.sh)       | instalacja polecenie po poleceniu, z oczekiwanym wynikiem przy kroku     |
| [tools-setup-automated.sh](tools-setup-automated.sh) | te same kroki automatycznie + `check <krok>` – sprawdzenie i podpowiedzi |
| [ssh-config](ssh-config)                             | wpisy do `~/.ssh/config` na laptopie: jump-box i maszyny kubeadm         |

## Przygotowanie jump-boxa

Zaloguj się na jump-box (`ssh kurs@<IP_jump-boxa>` albo RDP) i pobierz materiały:

```bash
git clone https://github.com/pnowy/docker-and-kubernetes.git
cd docker-and-kubernetes/srodowisko
```

**Wersja ręczna** – otwórz [tools-setup-manual.sh](tools-setup-manual.sh) i kopiuj polecenia do terminala **pojedynczo**, część po części. Po każdej części sprawdź wynik:

```bash
./tools-setup-automated.sh check docker   # ✓/✗ dla każdego elementu kroku i podpowiedź, jak naprawić
```

**Wersja automatyczna** – te same kroki jednym poleceniem; każdy krok kończy się tym samym sprawdzeniem:

```bash
./tools-setup-automated.sh shell docker k8s minikube   # część Docker i Kubernetes na minikube
./tools-setup-automated.sh ssh kubeadm kubeconfig      # sekcja Kubernetes 7 – klaster kubeadm na 3 VM
```

Albo wszystko naraz: `./tools-setup-automated.sh all`. Skrypt pyta o hasło do `sudo`, a w kroku `ssh` – jednorazowo o hasło każdej maszyny kubeadm. Każdy krok można powtórzyć: pomija to, co już jest zainstalowane. Na koniec wyloguj się i zaloguj ponownie – dopiero nowa sesja ma grupę `docker` i nową konfigurację basha.

Obie wersje możesz łączyć: krok nie wyszedł ręcznie → `./tools-setup-automated.sh <krok>` dokończy go albo `check <krok>` pokaże, co poprawić.

| Krok         | Część w wersji ręcznej | Co robi                                                                                                                                                    | Potrzebne od       |
| ------------ | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `shell`      | 1                      | bash: starship, aliasy `d`, `k`, `kctx`, `kns`, autouzupełnianie (docker, kubectl, helm, kubectx…, Tab z menu), zoxide, fzf, hstr (Ctrl+R), pbcopy/pbpaste | Docker 2 (dodatek) |
| `docker`     | 2                      | Docker Engine z Buildx i Compose z repozytorium Dockera, użytkownik w grupie `docker`, Docker Scout, lazydocker, dive, trivy                               | Docker 2           |
| `k8s`        | 3                      | kubectl, minikube, kind, helm 4, k9s, kubectx/kubens                                                                                                       | Kubernetes 2       |
| `minikube`   | 4                      | klaster `minikube` z Calico i addonami metrics-server, ingress, headlamp                                                                                   | Kubernetes 2       |
| `ssh`        | 5                      | klucz SSH jump-boxa, aliasy `k8s-cp`, `k8s-worker1`, `k8s-worker2` w `~/.ssh/config`, kopia klucza na VM                                                   | Kubernetes 7       |
| `kubeadm`    | 6                      | skrypty z [kubernetes/07-kubeadm](../kubernetes/07-kubeadm/) na VM: `kubeadm init`, Calico, `kubeadm join`                                                 | Kubernetes 7       |
| `kubeconfig` | 7                      | kontekst `kubeadm` w `~/.kube/config` jump-boxa obok `minikube`                                                                                            | Kubernetes 7       |
| `vscode`     | 8 (opcjonalnie)        | VS Code z repozytorium Microsoftu + rozszerzenia YAML, Kubernetes, Container Tools – do pracy na pulpicie RDP                                              | –                  |
| `dev`        | 9 (opcjonalnie)        | Node.js 24 (NodeSource) i uv – uruchomienie `app-node` i `app-python` bez Dockera                                                                          | –                  |

Kroki `vscode` i `dev` są opcjonalne: nie wchodzą do `all` ani do `check` bez kroku – `./tools-setup-automated.sh vscode dev`. `vscode` przydaje się tylko przy pracy na pulpicie jump-boxa (RDP); z laptopa wygodniej [VS Code przez SSH](#vs-code-przez-ssh). `dev` pozwala uruchomić aplikacje szkoleniowe bezpośrednio, bez kontenera – polecenia w części 9 wersji ręcznej. `check` bez kroku sprawdza wszystkie obowiązkowe. Inne adresy maszyn albo użytkownik: `CP_IP=10.4.0.50 WORKER_IPS="10.4.0.100 10.4.0.200" VM_USER=kurs ./tools-setup-automated.sh ssh`. Aktualizacja narzędzi do najnowszych wersji: `UPDATE=1 ./tools-setup-automated.sh k8s`. Docker oficjalnym skryptem [get.docker.com](https://get.docker.com) zamiast ręcznej konfiguracji repozytorium: `DOCKER_INSTALL=script ./tools-setup-automated.sh docker` (w wersji ręcznej – zakomentowany wariant pod częścią 2.2).

Przykład – Docker nie wstał:

```text
$ ./tools-setup-automated.sh check docker
==> Sprawdzenie: docker
    ✓ polecenie docker
    ✗ usługa docker działa
    ...
    Jak naprawić:
      ./tools-setup-automated.sh docker
      logi usługi: sudo systemctl status docker; sudo journalctl -u docker -n 50
```

**Oczekiwany wynik:** `./tools-setup-automated.sh check` kończy się `Wszystko OK` (same ✓). Prompt pokazuje kontekst klastra, np. `☸ minikube`; `kubectl config get-contexts` – konteksty `minikube` i `kubeadm`.

Te same tematy z omówieniem na zajęciach: [docker/02-instalacja](../docker/02-instalacja/) (`install-docker-ubuntu.sh`, `powloka.sh`), [kubernetes/02-instalacja](../kubernetes/02-instalacja/) (`opcja-a-minikube.sh`, `opcja-b-kind.sh`, `konteksty.sh`, `powloka.sh`) i [kubernetes/07-kubeadm](../kubernetes/07-kubeadm/) (`z-jump-boxa.sh`).

## SSH z laptopa

Logujesz się hasłem użytkownika `kurs` (od prowadzącego) – klucze SSH na laptopie nie są potrzebne.

1. Dopisz zawartość [ssh-config](ssh-config) do `~/.ssh/config` (Windows: `%USERPROFILE%\.ssh\config`) i wpisz w nim publiczny adres jump-boxa.
2. Połącz się:

   ```bash
   ssh alx-jumpbox     # hasło jump-boxa
   ssh alx-cp          # Control Plane przez jump-box (ProxyJump): hasło jump-boxa, potem hasło maszyny
   ```

Na macOS i Linuksie wpis `ControlMaster` sprawia, że hasło podajesz raz na 4 h – kolejne `ssh`, `scp` i VS Code korzystają z otwartego połączenia. Windows tego nie obsługuje: hasło przy każdym połączeniu.

`LocalForward` w [ssh-config](ssh-config) przekazuje porty z jump-boxa na laptop przy każdym `ssh alx-jumpbox`: polecenie `kubectl port-forward … 8080:80` na jump-boksie daje stronę pod `http://localhost:8080` w przeglądarce na laptopie (Headlamp, Grafana, notes-api).

## VS Code przez SSH

Pliki na jump-boksie edytujesz w VS Code na laptopie, a terminal VS Code działa na jump-boksie.

1. Zainstaluj w VS Code rozszerzenie **Remote - SSH** (`ms-vscode-remote.remote-ssh`).
2. `F1` → **Remote-SSH: Connect to Host…** → `alx-jumpbox` (VS Code czyta hosty z `~/.ssh/config`) i wpisz hasło w polu u góry okna. Za pierwszym razem VS Code instaluje na jump-boksie swój serwer – ok. 1 min.
3. **File → Open Folder** → `/home/kurs/docker-and-kubernetes`. Terminal (`` Ctrl+` ``) to powłoka jump-boxa.

Z terminala laptopa od razu do katalogu:

```bash
code --remote ssh-remote+alx-jumpbox /home/kurs/docker-and-kubernetes
```

Porty otwierane na jump-boksie (`kubectl port-forward`, `docker run -p`) VS Code przekazuje na laptop sam – lista w zakładce **Ports**. Na maszynach kubeadm (2 GB RAM) nie uruchamiaj serwera VS Code – pracuj na nich przez `ssh` z terminala.

<details>
<summary><strong>Najczęstsze problemy</strong></summary>

| Objaw                                                        | Przyczyna i rozwiązanie                                                                                                   |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| `permission denied … docker.sock`                            | stara sesja bez grupy `docker` – wyloguj się i zaloguj ponownie (albo `newgrp docker`)                                    |
| prompt bez zmian, brak `z`                                   | stara konfiguracja – `source ~/.bashrc`                                                                                   |
| `check kubeadm`: `✗ k8s-cp: kubelet działa`                  | najpierw krok `ssh` (`check ssh`)                                                                                         |
| `ssh k8s-cp` pyta o hasło mimo `ssh-copy-id`                 | obraz VM ma `PubkeyAuthentication no` (`ssh -v`: `can continue: password`) – krok 5.4 albo `tools-setup-automated.sh ssh` |
| `REMOTE HOST IDENTIFICATION HAS CHANGED`                     | maszyna przeinstalowana – `ssh-keygen -R <adres>` i połącz się ponownie                                                   |
| VS Code: `Could not establish connection`                    | najpierw `ssh alx-jumpbox` w terminalu; brak pola na hasło: ustawienie `remote.SSH.showLoginTerminal`                     |
| `kubectl --context kubeadm`: `x509: certificate signed by …` | klaster postawiony od nowa – powtórz krok `kubeconfig`                                                                    |

</details>
