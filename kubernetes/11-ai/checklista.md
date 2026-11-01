# Checklista weryfikacji manifestów wygenerowanych przez AI

Przed `kubectl apply` sprawdź każdy punkt. AI zna stare wersje dokumentacji i chętnie miesza pola z różnych wersji API.

## Składnia i API

| Sprawdź                                                                            | Jak                                                     |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `apiVersion` istnieje w klastrze (np. `apps/v1`, nie `extensions/v1beta1`)         | `kubectl api-resources`, `kubeconform -strict`          |
| pola istnieją w tej wersji API (np. Ingress v1: `service.name`, nie `serviceName`) | `kubectl explain ingress.spec.rules.http.paths.backend` |
| API Server przyjmuje manifest                                                      | `kubectl apply --dry-run=server -f plik.yaml`           |
| wymagane pola są na miejscu (np. `selector` w Deploymencie)                        | `kubeconform -strict -summary plik.yaml`                |

## Spójność z aplikacją

| Sprawdź                                                            | W notes-api                                  |
| ------------------------------------------------------------------ | -------------------------------------------- |
| `selector` Deploymentu i Serwisu pasuje do etykiet Poda            | `app: notes-api` w trzech miejscach          |
| `containerPort`, `targetPort` i port sond zgadzają się z aplikacją | aplikacja słucha na 3000                     |
| ścieżki sond istnieją                                              | `/healthz` (liveness), `/readyz` (readiness) |
| zmienne środowiskowe mają nazwy, których aplikacja oczekuje        | `STORAGE`, `PGHOST`, `PGPASSWORD_FILE`…      |

## Bezpieczeństwo i produkcja

| Sprawdź                                                            | Dlaczego                                                         |
| ------------------------------------------------------------------ | ---------------------------------------------------------------- |
| brak haseł w `env.value` i w repozytorium                          | hasło do Secretu (`secretKeyRef` lub plik z woluminu)            |
| obraz z konkretnym tagiem, nie `latest`                            | powtarzalne wdrożenia i rollback                                 |
| `imagePullPolicy` pasuje do źródła obrazu                          | `Always` przy obrazie tylko w minikube kończy się `ErrImagePull` |
| `resources.requests` i `limits`                                    | scheduler i HPA potrzebują requests, limits chronią węzeł        |
| readinessProbe obok livenessProbe                                  | bez readiness ruch trafia do Podów, które jeszcze nie są gotowe  |
| `securityContext` (`runAsNonRoot`, `readOnlyRootFilesystem`)       | ograniczenie skutków włamania do kontenera                       |
| typ Serwisu (`ClusterIP` za Ingressem zamiast `LoadBalancer`)      | `LoadBalancer` w chmurze to płatny, publiczny adres              |
| `ingressClassName` zamiast adnotacji `kubernetes.io/ingress.class` | adnotacja jest przestarzała od Kubernetesa 1.18                  |
| `namespace` – zamierzony, a nie domyślny `default`                 | `kubectl apply` bez namespace trafi tam, gdzie wskazuje kontekst |

## Narzędzia

| Narzędzie                                              | Co robi                                                                        |
| ------------------------------------------------------ | ------------------------------------------------------------------------------ |
| `kubectl apply --dry-run=server`                       | walidacja przez API Server klastra – najpewniejsza, ale wymaga klastra         |
| [kubeconform](https://github.com/yannh/kubeconform)    | walidacja schematów offline, także w CI                                        |
| [kube-linter](https://github.com/stackrox/kube-linter) | dobre praktyki: zasoby, sondy, `latest`, root, sekrety                         |
| `kubectl explain`                                      | dokumentacja pól z API Servera – sprawdź, czy pole wymyślone przez AI istnieje |
| `helm lint` · `helm template`                          | to samo dla chartów wygenerowanych przez AI                                    |
