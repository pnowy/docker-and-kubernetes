# Sekcja 10 – Troubleshooting: diagnostyka klastra

**Cel:** znaleźć przyczynę typowych awarii (Pending, ImagePullBackOff, CrashLoopBackOff, OOMKilled, Serwis bez Podów, PVC bez dysku) samymi poleceniami `kubectl` i naprawić je.
**Wymaga:** klastra minikube z addonem `metrics-server` ([sekcja 2](../02-instalacja/README.md)).

## Pliki w katalogu

| Plik                                                     | Do czego                                                               |
| -------------------------------------------------------- | ---------------------------------------------------------------------- |
| [diagnostyka.sh](diagnostyka.sh)                         | 10.1–10.4: CrashLoopBackOff, węzeł, sieć (netshoot), szybkie polecenia |
| [scenariusze/](scenariusze/)                             | ★ ćwiczenie: 6 zepsutych aplikacji w namespace `awarie`                |
| [scenariusze/rozwiazanie.sh](scenariusze/rozwiazanie.sh) | ★ diagnoza i poprawka każdego scenariusza                              |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:**

- `curl -v http://backend-svc` zamiast portu 8080 – backend z ćwiczenia 4.3 słucha na 80.
- `kubectl get componentstatuses` działa, ale jest przestarzałe od 1.19 (ostrzeżenie `Warning`); stan Control Plane pokazuje `kubectl get --raw='/readyz?verbose'`.
- `nicolaka/netshoot:v0.15` z przypiętą wersją zamiast `latest`.

## Schemat diagnozy

| Objaw (`kubectl get pods`)        | Pierwsze polecenie                    | Typowa przyczyna                                           |
| --------------------------------- | ------------------------------------- | ---------------------------------------------------------- |
| `Pending`                         | `kubectl describe pod X` → Events     | brak zasobów na węzłach, PVC bez dysku, nodeSelector/taint |
| `ErrImagePull`/`ImagePullBackOff` | `kubectl describe pod X` → Events     | literówka w nazwie lub tagu, prywatny rejestr bez hasła    |
| `CrashLoopBackOff`/`Error`        | `kubectl logs X --previous`           | błąd aplikacji, brak zmiennej, zły `command`               |
| `OOMKilled` (exit code 137)       | `kubectl describe pod X` → Last State | limit pamięci za niski albo wyciek pamięci                 |
| `Running`, ale `0/1` Ready        | `kubectl describe pod X` → Readiness  | sonda readiness nie przechodzi                             |
| Pody `Running`, Serwis milczy     | `kubectl get endpointslices`          | selektor Serwisu nie pasuje do etykiet, zły `targetPort`   |

## Ćwiczenie ★ – sześć awarii (ok. 25 min)

```bash
kubectl create namespace awarie
kubectl apply -f scenariusze/
kubectl -n awarie get pods,pvc
```

Każdy plik w [scenariusze/](scenariusze/) to jedna zepsuta aplikacja. Dla każdej: ustal przyczynę (nie zaglądając do YAML, tylko `get`, `describe`, `logs`, `events`), napraw ją poleceniem `kubectl` i sprawdź wynik.

1. `web` – Pody działają, ale Serwis `web` nie odpowiada.
2. `api` – nowa wersja nie startuje.
3. `worker` – startuje i pada.
4. `raport` – startuje i pada, choć w logach nie ma błędu.
5. `analityka` – czeka i czeka.
6. `archiwum` – Pod nie dostaje dysku.

**Oczekiwany wynik:** po poprawkach `kubectl -n awarie get pods,pvc` pokazuje wszystkie Pody `Running` i PVC `Bound`, a EndpointSlice Serwisu `web` – 2 adresy. Sprzątanie: `kubectl delete namespace awarie`.

<details>
<summary><strong>Rozwiązanie</strong></summary>

Polecenia w [scenariusze/rozwiazanie.sh](scenariusze/rozwiazanie.sh).

| Aplikacja   | Objaw                         | Przyczyna                                     | Poprawka                                                            |
| ----------- | ----------------------------- | --------------------------------------------- | ------------------------------------------------------------------- |
| `web`       | EndpointSlice `<unset>`       | selektor `app: frontend`, Pody `app: web`     | `kubectl patch service web` – selektor `app: web`                   |
| `api`       | `ImagePullBackOff`            | tag `nginx:1.299` nie istnieje                | `kubectl set image … api=nginx:1.29`                                |
| `worker`    | `CrashLoopBackOff`            | brak zmiennej `QUEUE_URL` (`logs --previous`) | `kubectl set env … QUEUE_URL=…`                                     |
| `raport`    | `OOMKilled`, exit code 137    | limit 32Mi, proces potrzebuje ok. 200 MB      | `kubectl set resources … --limits=memory=512Mi`                     |
| `analityka` | `Pending`, `Insufficient cpu` | request 16 CPU, węzeł ma mniej                | `kubectl set resources … --requests=cpu=100m`                       |
| `archiwum`  | Pod i PVC `Pending`           | StorageClass `szybki-ssd` nie istnieje        | usuń Pod i PVC (klasy w PVC nie można zmienić), utwórz z `standard` |

</details>

## Ściąga

| Polecenie                                                                | Opis                                        |
| ------------------------------------------------------------------------ | ------------------------------------------- |
| `kubectl describe pod X` · `kubectl get events --sort-by=.lastTimestamp` | przyczyna w zdarzeniach                     |
| `kubectl logs X --previous` · `logs X -c kontener`                       | logi poprzedniego uruchomienia, kontenera   |
| `kubectl get pods -A --field-selector=status.phase!=Running`             | wszystko, co nie działa                     |
| `kubectl get endpointslices -l kubernetes.io/service-name=X`             | czy Serwis ma Pody                          |
| `kubectl top nodes` · `kubectl top pods -A --sort-by=memory`             | zużycie zasobów                             |
| `kubectl describe node X`                                                | Conditions, Allocated resources             |
| `kubectl run t --image=nicolaka/netshoot:v0.15 --rm -it -- bash`         | Pod z narzędziami sieciowymi                |
| `kubectl debug -it X --image=busybox:1.37 --target=kontener`             | kontener diagnostyczny w działającym Podzie |
| `kubectl get --raw='/readyz?verbose'`                                    | stan API Servera                            |
