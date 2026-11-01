# Sekcja 8 – RBAC: kontrola dostępu

**Cel:** nadawać kontom tylko potrzebne uprawnienia (Role/ClusterRole + RoleBinding) i sprawdzać je `kubectl auth can-i`.
**Wymaga:** klastra minikube ([sekcja 2](../02-instalacja/README.md)), `jq`; do ćwiczenia ★ „konto dla CI” – namespace `notes` z notes-api (sekcje 3–5).

## Pliki w katalogu

| Plik                                                 | Do czego                                                                          |
| ---------------------------------------------------- | --------------------------------------------------------------------------------- |
| [rbac-pod-reader.yaml](rbac-pod-reader.yaml)         | 8.2: Namespace, ServiceAccount, Role `pod-reader`, RoleBinding                    |
| [rbac.sh](rbac.sh)                                   | 8.2: `auth can-i`; ★ Pod z prawdziwym tokenem, ClusterRole `view`, `create token` |
| [cwiczenie-ci-deployer/](cwiczenie-ci-deployer/)     | ★ ćwiczenie: konto dla CI – aktualizacja Deploymentów bez dostępu do Secretów     |
| [cwiczenie-sa-kubeconfig/](cwiczenie-sa-kubeconfig/) | ★ ćwiczenie: logowanie kontem ServiceAccount – token i własny plik kubeconfig     |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnica względem materiałów ALX:** materiały pokazują tylko Role i RoleBinding; namespace `testowa` i konto `monitoring-agent` muszą jednak istnieć, dlatego [rbac-pod-reader.yaml](rbac-pod-reader.yaml) tworzy je w tym samym pliku.

## Ćwiczenie 8.2 – tylko odczyt Podów (ok. 10 min)

Wykonaj polecenia z [rbac.sh](rbac.sh).

**Oczekiwany wynik:** `can-i list pods` w `testowa` – `yes`, `delete deployments` – `no`, a `list pods` w `default` – `no` (Role działa w jednym namespace). Pod na koncie `monitoring-agent` listuje Pody, a `get secrets` kończy się `Forbidden`. Po RoleBinding do ClusterRole `view` konto widzi też Deploymenty i Serwisy – nadal tylko w `testowa`.

## Ćwiczenie ★ – konto dla CI (ok. 15 min)

Przygotuj w namespace `notes` konto `ci-deployer` dla pipeline'u wdrożeniowego. Konto ma:

- aktualizować istniejące Deploymenty (`kubectl set image`, `rollout undo`) i czekać na rollout (`rollout status`),
- czytać Pody i ich logi,
- **nie** tworzyć nowych Deploymentów, **nie** usuwać Podów i **nie** czytać Secretów.

Sprawdź uprawnienia `kubectl auth can-i … --as=system:serviceaccount:notes:ci-deployer` i wykonaj wdrożenie `kubectl --as=… set image`.

**Oczekiwany wynik:** `patch deployments` – `yes`; `create deployments`, `get secrets`, `delete pods` i cokolwiek w `default` – `no`; `set image` i `rollout status` jako `ci-deployer` działają.

<details>
<summary><strong>Rozwiązanie</strong></summary>

[cwiczenie-ci-deployer/ci-deployer.yaml](cwiczenie-ci-deployer/ci-deployer.yaml) i polecenia w [cwiczenie-ci-deployer/rozwiazanie.sh](cwiczenie-ci-deployer/rozwiazanie.sh). Dwie pułapki:

- Deploymenty i ReplicaSety są w grupie API `apps` – reguła z `apiGroups: [""]` nie zadziała. Grupę sprawdzisz w `kubectl api-resources` (kolumna APIVERSION).
- `kubectl rollout status` czyta ReplicaSety, więc konto potrzebuje do nich `get/list/watch`, inaczej rollout kończy się `Forbidden`.

</details>

## Ćwiczenie ★ – logowanie kontem ServiceAccount (ok. 15 min)

`--as=` tylko udaje konto – nadal logujesz się jako administrator. Tym razem zaloguj się do klastra **naprawdę** jako ServiceAccount, tak jak zrobi to osoba albo narzędzie, które dostanie od ciebie tylko plik kubeconfig.

1. Utwórz namespace `zespol-a`, konto `deweloper` i RoleBinding do wbudowanej ClusterRole `edit` (tylko w `zespol-a`).
2. Wygeneruj token konta: `kubectl create token deweloper -n zespol-a --duration=8h`. Odkoduj środkową część tokena (JWT) i znajdź w niej `sub` oraz `exp`.
3. Zbuduj **osobny** plik `deweloper.kubeconfig` poleceniami `kubectl config --kubeconfig=… set-cluster / set-credentials / set-context / use-context`. Adres API Servera i certyfikat CA weź z bieżącego kontekstu (`kubectl config view --minify --flatten`).
4. Z `KUBECONFIG=./deweloper.kubeconfig` sprawdź `kubectl auth whoami`, utwórz Deployment, wylistuj Pody w `zespol-a` i w `default`, wylistuj węzły i spróbuj nadać sobie rolę `admin`.
5. Wyślij to samo zapytanie `curl` z nagłówkiem `Authorization: Bearer <token>`.
6. Usuń konto `deweloper` i sprawdź, czy token nadal działa.

**Oczekiwany wynik:** `auth whoami` pokazuje `system:serviceaccount:zespol-a:deweloper`. Deployment i lista Podów w `zespol-a` działają. Pody w `default`, węzły i `create rolebinding` kończą się `Forbidden`. `curl` zwraca te same Pody. Po usunięciu konta (i ok. 10 s pamięci podręcznej API Servera) dostajesz `Unauthorized`.

<details>
<summary><strong>Rozwiązanie</strong></summary>

[cwiczenie-sa-kubeconfig/deweloper.yaml](cwiczenie-sa-kubeconfig/deweloper.yaml) i polecenia w [cwiczenie-sa-kubeconfig/rozwiazanie.sh](cwiczenie-sa-kubeconfig/rozwiazanie.sh). Warto wiedzieć:

- **Dwa rodzaje tokenów.** `kubectl create token` daje token krótkotrwały: wygasa sam i nie jest zapisany w klastrze. Secret typu `kubernetes.io/service-account-token` (jest w manifeście) daje token bez terminu ważności – unieważnisz go, usuwając Secret. Do CI i ludzi wybieraj krótkotrwały.
- **`--flatten`.** minikube trzyma CA w osobnym pliku na twoim dysku – `--flatten` wkleja go do wyniku jako base64, a `--embed-certs` zapisuje go w nowym kubeconfig. Plik działa wtedy na innym komputerze.
- **`edit` nie nadaje uprawnień.** Rola pozwala tworzyć i zmieniać obiekty (także czytać Secrety), ale nie Role ani RoleBindingi – konto nie podniesie sobie uprawnień.
- **Pliku kubeconfig z tokenem nie commituj** – to hasło do klastra. Katalog ma `.gitignore` na `ca.crt` i `*.kubeconfig`.

</details>

## Ściąga

| Polecenie                                                                            | Opis                        |
| ------------------------------------------------------------------------------------ | --------------------------- |
| `kubectl auth can-i VERB ZASÓB [-n NS]`                                              | czy ja mogę                 |
| `kubectl auth can-i VERB ZASÓB --as=system:serviceaccount:NS:KONTO`                  | czy konto może              |
| `kubectl auth can-i --list --as=…`                                                   | wszystkie uprawnienia konta |
| `kubectl create serviceaccount X`                                                    | konto dla aplikacji lub CI  |
| `kubectl create role X --verb=get,list --resource=pods`                              | Role imperatywnie           |
| `kubectl create rolebinding X --role=Y \| --clusterrole=Y --serviceaccount=NS:KONTO` | przypisanie roli            |
| `kubectl create token KONTO --duration=1h`                                           | krótkotrwały token konta    |
| `kubectl config --kubeconfig=PLIK set-credentials KONTO --token=…`                   | token w osobnym kubeconfig  |
| `kubectl auth whoami`                                                                | kim jestem dla API Servera  |
| `kubectl get clusterroles view edit admin cluster-admin`                             | wbudowane role              |
