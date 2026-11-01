# Sekcja 2 – Instalacja Kubernetesa

**Cel:** uruchomić klaster minikube, na którym robimy wszystkie ćwiczenia poza sekcją 7, i poznać inne metody instalacji (kind, k3s).
**Wymaga:** jump-boxa z Dockerem (część Docker szkolenia). Każdy uczestnik ma własny jump-box i własny klaster.

## Pliki w katalogu

| Plik                                           | Do czego                                                                                        |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [opcja-a-minikube.sh](opcja-a-minikube.sh)     | kroki 7–11: minikube, kubectl, addony, UI – **klaster na całe szkolenie**                       |
| [opcja-b-kind.sh](opcja-b-kind.sh)             | kroki 12–14: kind, klaster jedno- i wielowęzłowy                                                |
| [kind-config.yaml](kind-config.yaml)           | kind: 1 control-plane + 2 workery (krok 14)                                                     |
| [opcja-c-k3s.sh](opcja-c-k3s.sh)               | krok 15: k3s – tylko pokaz, na osobnej maszynie Linux                                           |
| [cwiczenie-kind-lab.sh](cwiczenie-kind-lab.sh) | ćwiczenie 2.5 (kroki 16–21): klaster kind z mapowaniem portów i obrazem notes-api               |
| [klaster.yaml](klaster.yaml)                   | kind: control-plane z portami 80/443 i etykietą `ingress-ready` + 2 workery                     |
| [konteksty.sh](konteksty.sh)                   | dodatek: przełączanie klastrów i namespace'ów, instalacja kubectx i kubens                      |
| [powloka.sh](powloka.sh)                       | dodatek: autouzupełnianie kubectl/minikube/kind/kubectx, kontekst klastra w prompcie (starship) |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:**

- `minikube start` dostaje `--cni=calico`: domyślna sieć minikube nie egzekwuje NetworkPolicy, a ćwiczenie 4.3 jej potrzebuje. Raz utworzonego klastra nie przełączysz na inną sieć – trzeba `minikube delete` i start od nowa.
- Kubernetes Dashboard został wycofany (repozytorium zarchiwizowane), dlatego w kroku 10–11 włączamy addon **Headlamp**. Dashboard opisujemy w sekcji 6 tylko jako historię.
- kind w wersji v0.33.0 zamiast v0.20.0 z materiałów (v0.20.0 tworzy klaster z Kubernetesem 1.27, od dawna bez poprawek).

## Praca na jump-boksie

Jump-box to Linux, więc adres klastra (`minikube ip`, zwykle `192.168.49.2`) jest osiągalny bezpośrednio z jump-boxa – `minikube tunnel` z materiałów jest potrzebny tylko na macOS i Windows. Przeglądarka działa na Twoim laptopie, dlatego UI i Grafanę otwierasz przez tunel SSH:

```bash
# na laptopie
ssh -L 8080:localhost:8080 <użytkownik>@<jump-box>
# na jump-boksie, w tej sesji SSH
kubectl -n headlamp port-forward svc/headlamp 8080:80
```

i otwierasz `http://localhost:8080` w przeglądarce laptopa.

## Ćwiczenie 2.3 – instalacja minikube (ok. 15 min)

Wykonaj kroki 7–11 z [opcja-a-minikube.sh](opcja-a-minikube.sh). Jeśli na jump-boksie są już `minikube` i `kubectl`, zacznij od kroku 9.

**Oczekiwany wynik:** `minikube status` pokazuje `host`, `kubelet`, `apiserver`: `Running`; `kubectl get nodes` – jeden węzeł `minikube` w stanie `Ready`; `minikube addons list` – włączone `metrics-server`, `ingress`, `headlamp`; po zalogowaniu tokenem Headlamp pokazuje Pody z `kube-system`.

## Ćwiczenie 2.5 – klaster kind (ok. 10 min)

Wykonaj kroki 16–21 z [cwiczenie-kind-lab.sh](cwiczenie-kind-lab.sh). Klaster kind działa obok minikube – każdy klaster to osobny **kontekst** `kubectl`:

```bash
kubectl config get-contexts        # minikube i kind-lab-klaster
kubectl config use-context minikube
```

### Kilka klastrów naraz: konteksty, kubectx, kubens (dodatek, ok. 5 min)

Przed krokiem 21 (usunięcie klastra kind) wykonaj [konteksty.sh](konteksty.sh). Każdy `kubectl` trafia do klastra z **bieżącego kontekstu** – przed `delete` czy `apply` sprawdź `kubectl config current-context`.

| Zadanie                        | kubectl                                                  | kubectx / kubens           |
| ------------------------------ | -------------------------------------------------------- | -------------------------- |
| lista klastrów                 | `kubectl config get-contexts`                            | `kubectx`                  |
| przełącz klaster               | `kubectl config use-context kind-lab-klaster`            | `kubectx kind-lab-klaster` |
| wróć do poprzedniego           | –                                                        | `kubectx -`                |
| jedno polecenie w innym        | `kubectl --context minikube get nodes`                   | –                          |
| domyślny namespace             | `kubectl config set-context --current --namespace=notes` | `kubens notes`             |
| wróć do poprzedniego namespace | –                                                        | `kubens -`                 |

kubectx i kubens to dwa pliki binarne z [github.com/ahmetb/kubectx](https://github.com/ahmetb/kubectx) – instalacja w kroku B skryptu (albo `sudo apt install kubectx`, albo `kubectl krew install ctx ns`). Zmieniają tylko `~/.kube/config`, tak samo jak `kubectl config`.

**Oczekiwany wynik:** `kubectx` pokazuje `minikube` i `kind-lab-klaster`; po `kubens kube-system` polecenie `kubectl get pods` bez `-n` wyświetla Pody systemowe; na końcu bieżący kontekst to `minikube`, namespace `default`.

### Autouzupełnianie i kontekst w prompcie (dodatek, ok. 5 min)

Wykonaj [powloka.sh](powloka.sh). Krok 1 (bash) działa od razu; kroki 2–3 zakładają zsh, oh-my-zsh i starship z części Docker ([docker/02-instalacja/powloka.sh](../../docker/02-instalacja/powloka.sh)).

| Krok                         | Co daje                                                                                    |
| ---------------------------- | ------------------------------------------------------------------------------------------ |
| bash: `kubectl completion`   | Tab podpowiada zasoby, nazwy Podów, flagi; alias `k` z tym samym uzupełnianiem             |
| zsh: wtyczki oh-my-zsh       | `kubectl`, `minikube`, `kind` – uzupełnianie i aliasy (`k`, `kgp`, `kaf`, `kdp`)           |
| kubectx / kubens             | pliki uzupełniania z repozytorium kubectx – `kubens <TAB>` podpowiada namespace'y          |
| starship: moduł `kubernetes` | prompt `☸ minikube (notes)` – kontekst i namespace; kontekst z `prod` w nazwie na czerwono |

Moduł `kubernetes` w starship jest **domyślnie wyłączony** – skrypt dopisuje `disabled = false` do `~/.config/starship.toml`.

**Oczekiwany wynik:** `kubectl get po<TAB>` uzupełnia do `pods`; po `kubens kube-system` prompt pokazuje `☸ minikube (kube-system)`; na końcu `kubens default`.

**Uwaga:** jeśli `kind create cluster` kończy się błędem `bind: address already in use`, port 80 lub 443 jump-boxa jest zajęty. Zmień w [klaster.yaml](klaster.yaml) `hostPort` na `8080` i `8443`.

**Oczekiwany wynik:** 3 węzły `Ready` (`lab-klaster-control-plane`, `lab-klaster-worker`, `lab-klaster-worker2`); `crictl images` na węźle pokazuje `moja-app:latest`; po kroku 21 `kubectl config current-context` znów zwraca `minikube`.

## Porównanie (2.4)

| Cecha     | minikube          | kind              | k3s              | kubeadm (sekcja 7)    |
| --------- | ----------------- | ----------------- | ---------------- | --------------------- |
| Cel       | nauka, dev        | CI/CD, testy      | edge, lekka prod | produkcja             |
| Węzły     | 1 (lub `--nodes`) | wiele (kontenery) | wiele            | wiele (VM/bare metal) |
| Addony    | wbudowane         | ręczna instalacja | wbudowane        | ręczna instalacja     |
| Produkcja | nie               | nie               | tak              | tak                   |

## Ściąga

| Polecenie                                       | Opis                                         |
| ----------------------------------------------- | -------------------------------------------- |
| `minikube start` · `stop` · `delete`            | uruchom, zatrzymaj, usuń klaster             |
| `minikube status` · `minikube ip`               | stan klastra, adres węzła                    |
| `minikube addons list` · `enable X`             | dodatki klastra                              |
| `minikube ssh`                                  | powłoka na węźle minikube                    |
| `minikube image load obraz:tag`                 | skopiuj obraz z Dockera jump-boxa do klastra |
| `kind create cluster --name X --config plik`    | klaster kind                                 |
| `kind load docker-image obraz:tag --name X`     | obraz do węzłów kind                         |
| `kubectl config get-contexts` · `use-context X` | lista klastrów, przełączenie                 |
| `kubectx X` · `kubectx -`                       | przełącz klaster, wróć do poprzedniego       |
| `kubens X` · `kubens -`                         | przełącz namespace, wróć do poprzedniego     |
