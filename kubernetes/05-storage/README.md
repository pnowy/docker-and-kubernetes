# Sekcja 5 – Storage w Kubernetesie

**Cel:** przechowywać dane poza cyklem życia Poda: PersistentVolume, PersistentVolumeClaim, StorageClass i StatefulSet z PostgreSQL. Dodatkowo (★): init container, Job i CronJob, notes-api z bazą.
**Wymaga:** klastra minikube ([sekcja 2](../02-instalacja/README.md)); do ćwiczenia ★ – namespace `notes` z ćwiczeń [sekcji 3](../03-podstawowe-operacje/README.md) i [sekcji 4](../04-networking/README.md).

## Pliki w katalogu

| Plik                                                                          | Do czego                                                                       |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| [persistent-volume.yaml](persistent-volume.yaml)                              | 5.1: statyczny PV `hostPath`                                                   |
| [persistent-volume-claim.yaml](persistent-volume-claim.yaml)                  | 5.1: PVC 2 Gi                                                                  |
| [pod-z-pvc.yaml](pod-z-pvc.yaml)                                              | 5.1: PostgreSQL w Podzie z PVC                                                 |
| [01-storageclass.sh](01-storageclass.sh)                                      | 5.2: StorageClass minikube; ★ własna klasa z `Retain`                          |
| [storageclass-minikube.yaml](storageclass-minikube.yaml)                      | ★ klasa `zachowaj` i PVC do niej                                               |
| [storageclass-aws.yaml](storageclass-aws.yaml)                                | 5.2: klasa z materiałów – tylko AWS EKS                                        |
| [cwiczenie.sh](cwiczenie.sh)                                                  | ćwiczenie 5.3 (kroki 27–31): PVC, StatefulSet PostgreSQL, trwałość danych      |
| [postgres-statefulset.yaml](postgres-statefulset.yaml)                        | StatefulSet z kroku 29                                                         |
| [02-job-cronjob.sh](02-job-cronjob.sh) · [job-cronjob.yaml](job-cronjob.yaml) | ★ Job i CronJob                                                                |
| [cwiczenie-notes-api/](cwiczenie-notes-api/)                                  | ★ ćwiczenie: notes-api z PostgreSQL – Secret, StatefulSet, init container, Job |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:**

- `postgres:18` zamiast `postgres:15` i wolumin montowany w `/var/lib/postgresql` zamiast `/var/lib/postgresql/data` – od wersji 18 obraz trzyma dane w podkatalogu z numerem wersji (tak samo jak w `compose.yaml` z części Docker).
- Domyślna StorageClass minikube to `standard` z provisionerem `k8s.io/minikube-hostpath` (w materiałach: `docker.io/hostpath` – to Docker Desktop). Ma `volumeBindingMode: Immediate`, więc PVC z kroku 28 od razu ma status `Bound`, a nie `Pending`.
- Pod Ready ≠ baza gotowa: po `kubectl wait` skrypt czeka jeszcze na `pg_isready`, inaczej `psql` w kroku 30 może trafić na startujący serwer.
- StatefulSet z kroku 29 wskazuje `serviceName: postgres`, ale materiały nie tworzą takiego Serwisu – baza działa, tylko nie ma nazwy DNS `postgres-0.postgres`. Wersja z headless Service jest w ćwiczeniu ★.

## Ćwiczenie 5.3 – zarządzanie danymi (ok. 15 min)

Wykonaj kroki 27–31 z [cwiczenie.sh](cwiczenie.sh). Statyczny PV na początku skryptu jest opcjonalny – pokazuje, że PVC bez `storageClassName: ""` nie wiąże się z ręcznie utworzonym PV, tylko trafia do domyślnej klasy.

**Oczekiwany wynik:** `moj-pvc` i `db-data-postgres-0` mają status `Bound`, a `moj-pv` zostaje `Available`. Po usunięciu Poda `postgres-0` StatefulSet tworzy Pod o tej samej nazwie i `SELECT * FROM test;` zwraca wiersz `Dane przetrwają restart`. Po usunięciu StatefulSetu PVC `db-data-postgres-0` zostaje – trzeba go usunąć ręcznie.

## Ćwiczenie ★ – notes-api z PostgreSQL (ok. 25 min)

Pliki: [cwiczenie-notes-api/](cwiczenie-notes-api/), polecenia w [cwiczenie-notes-api/rozwiazanie.sh](cwiczenie-notes-api/rozwiazanie.sh).

1. Utwórz Secret `notes-db` z kluczem `password` poleceniem `kubectl create secret` (hasło nie trafia do Gita).
2. Wdróż PostgreSQL 18 jako StatefulSet `notes-db` z headless Service i PVC z `volumeClaimTemplates`. Hasło baza czyta z pliku (`POSTGRES_PASSWORD_FILE`), jak w `compose.yaml` z części Docker.
3. Przełącz notes-api na bazę: ConfigMap ze `STORAGE=postgres` i zmiennymi `PG*`, Secret jako plik (`PGPASSWORD_FILE`), init container, który czeka na `pg_isready`.
4. Dodaj notatkę i odpytaj `/notes` kilka razy. Czy oba Pody widzą to samo?
5. Uruchom Job `notes-seed`, który wstawia notatkę bezpośrednio do bazy.
6. Usuń Pod `notes-db-0` i sprawdź, czy notatki przetrwały.

**Uwaga:** NetworkPolicy `domyslnie-blokuj` z sekcji 4 blokuje też bazę – bez [network-policy-db.yaml](cwiczenie-notes-api/network-policy-db.yaml) init container czeka w nieskończoność. To dobry moment, żeby to sprawdzić: wdróż bazę bez tej polityki i obejrzyj `kubectl -n notes logs <pod> -c czekaj-na-baze`.

**Oczekiwany wynik:** `curl` zwraca `"storage":"postgres"`; każde zapytanie o `/notes` zwraca tę samą listę (w sekcji 3 każdy Pod miał własny plik). Job kończy się `INSERT 0 1`, a po usunięciu `notes-db-0` obie notatki są nadal w bazie.

## Ściąga

| Polecenie                                            | Opis                                        |
| ---------------------------------------------------- | ------------------------------------------- |
| `kubectl get sc` · `pv` · `pvc`                      | klasy, wolumeny, żądania                    |
| `kubectl describe pvc X`                             | dlaczego PVC jest `Pending` (sekcja Events) |
| `kubectl get sts` · `rollout status sts/X`           | StatefulSety                                |
| `kubectl exec -it X-0 -- psql -U postgres`           | konsola bazy w Podzie                       |
| `kubectl create secret generic X --from-literal=K=V` | Secret bez pliku w repozytorium             |
| `kubectl logs X -c init-kontener`                    | logi init containera                        |
| `kubectl get jobs,cronjobs` · `logs job/X`           | zadania i ich wynik                         |
| `kubectl create job --from=cronjob/X Y`              | uruchom CronJob od razu                     |
