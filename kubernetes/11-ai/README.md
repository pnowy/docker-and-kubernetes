# Sekcja 11 (dodatek) – AI w pracy z Kubernetesem

**Cel:** korzystać z AI przy pisaniu manifestów i diagnostyce klastra, ale każdy wynik weryfikować narzędziami i własną wiedzą o aplikacji.
**Wymaga:** klastra minikube z namespace `notes` z sekcji 5 (do wdrożenia poprawionej wersji) i scenariuszy z [sekcji 10](../10-troubleshooting/README.md).

## Pliki w katalogu

| Plik                                                       | Do czego                                                                          |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------- |
| [prompt.md](prompt.md)                                     | przykład dobrego promptu z kontekstem i wymaganiami                               |
| [wygenerowany/notes-api.yaml](wygenerowany/notes-api.yaml) | typowa odpowiedź AI na krótki prompt – z błędami                                  |
| [checklista.md](checklista.md)                             | checklista weryfikacji manifestów i narzędzia                                     |
| [rozwiazanie/notes-api.yaml](rozwiazanie/notes-api.yaml)   | poprawiona wersja: stabilne API, porty i sondy aplikacji, Secret, securityContext |
| [ai.sh](ai.sh)                                             | kubeconform, kube-linter, `--dry-run=server`, `kubectl diff`, k8sgpt, kubectl-ai  |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Ćwiczenie – znajdź błędy (ok. 15 min)

1. Przejrzyj [wygenerowany/notes-api.yaml](wygenerowany/notes-api.yaml) według [checklista.md](checklista.md) i wypisz wszystkie problemy – najpierw sam, bez narzędzi.
2. Uruchom `kubeconform`, `kubectl apply --dry-run=server` i `kube-linter` (polecenia w [ai.sh](ai.sh)). Które z Twoich problemów znalazły narzędzia, a których nie?
3. Porównaj z [rozwiazanie/notes-api.yaml](rozwiazanie/notes-api.yaml) i wdróż poprawioną wersję do namespace `notes`.

**Oczekiwany wynik:** co najmniej 10 problemów, m.in. `extensions/v1beta1` (usunięte w 1.16), brak `selector`, etykieta `app: notes` niezgodna z selektorem Serwisu `app: notes-api`, `notes-api:latest` z `imagePullPolicy: Always` (obraz jest tylko w minikube), hasło w `env.value`, port 8080 i sonda `/health` zamiast 3000 i `/healthz`, brak readinessProbe i zasobów, Serwis `LoadBalancer` za Ingressem, przestarzała adnotacja `ingress.class`, pola `serviceName`/`servicePort` z Ingress v1beta1, brak namespace. Narzędzia znajdują błędy API, brak selektora, `latest`, root i brak zasobów – ale **nie** zły port ani ścieżkę sondy: to wie tylko ktoś, kto zna aplikację.

## Diagnostyka z k8sgpt (ok. 10 min)

Wgraj scenariusze awarii z sekcji 10 i uruchom `k8sgpt analyze --namespace awarie`. Analizatory k8sgpt działają **bez** modelu językowego – zbierają to, co pokazałyby `kubectl describe` i `events`, w jedną listę. Opcja `--explain` wysyła opis błędów do wybranego dostawcy AI (`k8sgpt auth list` pokazuje obsługiwanych, w tym modele lokalne przez Ollama); `--anonymize` maskuje nazwy obiektów.

**Oczekiwany wynik:** k8sgpt wskazuje wszystkie 6 awarii: Serwis bez endpointów z oczekiwaną etykietą `app=frontend`, `nginx:1.299` not found, `OOMKilled`, `exitCode=1`, `Insufficient cpu` i brakującą StorageClass `szybki-ssd`.

## Zasady pracy z AI w klastrze

- **Weryfikuj przed `apply`:** `kubeconform` → `kubectl apply --dry-run=server` → `kubectl diff` → przegląd według checklisty.
- **Podawaj kontekst:** wersję Kubernetesa, porty, ścieżki sond, nazwy zmiennych i Secretów – inaczej AI je zgaduje ([prompt.md](prompt.md)).
- **Agent dostaje najmniejsze uprawnienia:** kubectl-ai i podobne agenty wykonują polecenia z Twoim kubeconfigiem. Dawaj im konto z ClusterRole `view` ([sekcja 8](../08-rbac/README.md)), nie `cluster-admin`.
- **Uważaj, co wysyłasz:** logi, opisy Podów i manifesty mogą zawierać nazwy klientów, adresy i sekrety. Na klastrze z danymi firmy używaj modelu zatwierdzonego przez firmę albo lokalnego.

## Ściąga

| Polecenie                                       | Opis                                      |
| ----------------------------------------------- | ----------------------------------------- |
| `kubeconform -strict -summary plik.yaml`        | walidacja schematów offline               |
| `kube-linter lint plik.yaml`                    | dobre praktyki                            |
| `kubectl apply --dry-run=server -f plik.yaml`   | walidacja przez API Server                |
| `kubectl diff -f plik.yaml`                     | podgląd zmian przed `apply`               |
| `kubectl explain ZASÓB.pole --recursive`        | czy pole istnieje                         |
| `k8sgpt analyze [--namespace X] [--filter=Pod]` | lista problemów w klastrze                |
| `k8sgpt analyze --explain --anonymize`          | wyjaśnienie od modelu, z maskowaniem nazw |
