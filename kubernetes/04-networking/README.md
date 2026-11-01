# Sekcja 4 – Networking w Kubernetesie

**Cel:** wystawić aplikację przez Service i Ingress, sprawdzić DNS w klastrze i ograniczyć ruch NetworkPolicy. Dodatkowo (★): Gateway API – następca Ingress.
**Wymaga:** klastra minikube z `--cni=calico` i addonem `ingress` ([sekcja 2](../02-instalacja/README.md)); do ćwiczenia ★ – Deploymentu notes-api z [sekcji 3](../03-podstawowe-operacje/README.md).

## Pliki w katalogu

| Plik                                                                  | Do czego                                                                                                               |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [01-serwisy.sh](01-serwisy.sh)                                        | 4.2: ClusterIP, EndpointSlice, namespace i DNS, NodePort, LoadBalancer (`minikube tunnel`), ExternalName               |
| [service.yaml](service.yaml)                                          | Service z materiałów (`nginx-service`)                                                                                 |
| [namespace.yaml](namespace.yaml)                                      | namespace `staging` do pokazania pełnej nazwy DNS Serwisu                                                              |
| [products.yaml](products.yaml)                                        | Deployment httpbin + Service `products` w `staging` – toolbox z `default` woła go po nazwie DNS                        |
| [cwiczenie.sh](cwiczenie.sh)                                          | ćwiczenie 4.3 (kroki 22–26): frontend, backend, DNS, Ingress, NetworkPolicy                                            |
| [ingress.yaml](ingress.yaml)                                          | Ingress z materiałów, nazwy Serwisów dopasowane do ćwiczenia                                                           |
| [network-policy.yaml](network-policy.yaml)                            | NetworkPolicy z materiałów: do backendu tylko z Podów `app=frontend`                                                   |
| [02-gateway-api.sh](02-gateway-api.sh) · [gateway.yaml](gateway.yaml) | ★ Envoy Gateway, GatewayClass, Gateway, HTTPRoute dla notes-api; krok 0 przygotowuje notes-api, gdy nie było ćwiczeń ★ |
| [cwiczenie-notes-api/](cwiczenie-notes-api/)                          | ★ ćwiczenie: notes-api za Serwisem i Ingressem, NetworkPolicy dla namespace                                            |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:**

- Ingress testujemy na `$(minikube ip)` z nagłówkiem `Host:` zamiast `minikube tunnel` i wpisu w `/etc/hosts` – jump-box to Linux i widzi adres węzła minikube bezpośrednio. Na macOS i Windows potrzebny jest `minikube tunnel` w osobnym terminalu i adres `127.0.0.1`. Opcjonalnie host `app.$(minikube ip).nip.io` – publiczny DNS nip.io zwraca adres zapisany w nazwie, więc aplikację można otworzyć w przeglądarce na pulpicie jump-boksa bez `/etc/hosts`.
- Port 80 zamiast 8080 w Ingress i NetworkPolicy – backend z ćwiczenia (httpd) słucha na 80.
- `wget -T 5` w kroku 26: bez limitu czasu `wget` czeka kilka minut, zanim zgłosi timeout.
- Kontroler z addonu `ingress` to ingress-nginx, którego rozwój zakończono w marcu 2026 (bez poprawek bezpieczeństwa). Na zajęciach używamy go, bo tego dotyczą materiały; w nowych projektach wybierz Gateway API (★).

## Ćwiczenie 4.3 – konfiguracja sieci (ok. 20 min)

Wykonaj kroki 22–26 z [cwiczenie.sh](cwiczenie.sh).

**Oczekiwany wynik:** z Poda `debug` `wget` zwraca stronę nginx, a `nslookup backend-svc` – adres ClusterIP. Przez Ingress `/` zwraca stronę nginx, a `/api` – `It works!` z httpd. Po NetworkPolicy Pod `unauthorized` kończy się `download timed out`, Pod z etykietą `app=frontend` dostaje stronę, a `/api` przez Ingress zwraca `504 Gateway Time-out`.

<details>
<summary><strong>Dlaczego Ingress dostaje 504?</strong></summary>

NetworkPolicy wpuszcza do backendu tylko Pody z etykietą `app=frontend` z **tego samego** namespace. Kontroler Ingress to Pod w namespace `ingress-nginx` bez tej etykiety, więc też jest blokowany. Rozwiązanie: dopisać w `from` regułę `namespaceSelector` dla `ingress-nginx` – tak robi ćwiczenie ★ niżej.

</details>

## Ćwiczenie ★ – notes-api w sieci klastra (ok. 20 min)

Pliki: [cwiczenie-notes-api/](cwiczenie-notes-api/), polecenia w [cwiczenie-notes-api/rozwiazanie.sh](cwiczenie-notes-api/rozwiazanie.sh).

1. Utwórz w namespace `notes` Service `notes-api` (port 80 → 3000) i Ingress dla hosta `notes.local`.
2. Wyślij kilka zapytań przez Ingress. Które pole odpowiedzi pokazuje, że Serwis rozkłada ruch?
3. Z Poda w namespace `default` wywołaj notes-api po nazwie DNS. Jaka jest pełna nazwa?
4. Zablokuj cały ruch przychodzący w namespace `notes` i wpuść do notes-api tylko kontroler Ingress (i Envoy Gateway z części ★).

**Oczekiwany wynik:** w odpowiedziach zmienia się `hostname` (2 Pody). Pełna nazwa to `notes-api.notes.svc.cluster.local` (wystarczy `notes-api.notes`). Po kroku 4 Pod z `default` dostaje `download timed out`, a Ingress nadal odpowiada.

Rozwiązanie kroku 4: [cwiczenie-notes-api/network-policy.yaml](cwiczenie-notes-api/network-policy.yaml) – polityka `podSelector: {}` bez reguł `ingress` blokuje wszystko, druga polityka wpuszcza namespace'y kontrolerów (`namespaceSelector`) na port kontenera 3000.

## ★ Gateway API (ok. 15 min, demo)

[02-gateway-api.sh](02-gateway-api.sh) instaluje kontroler Envoy Gateway i kieruje `notes.local` do notes-api przez HTTPRoute. W odróżnieniu od Ingress role są rozdzielone: GatewayClass (kontroler, admin klastra) → Gateway (wejście i porty, operator) → HTTPRoute (reguły, zespół aplikacji).

**Oczekiwany wynik:** `curl -H "Host: notes.local" http://localhost:8888/` zwraca JSON notes-api, inny host – `404`.

## Ściąga

| Polecenie                                                 | Opis                             |
| --------------------------------------------------------- | -------------------------------- |
| `kubectl expose deployment X --port=80 [--type=NodePort]` | Service dla Deploymentu          |
| `kubectl get svc` · `get endpointslices`                  | Serwisy, adresy Podów za nimi    |
| `kubectl run t --image=busybox:1.37 --rm -it -- sh`       | Pod do testów sieci              |
| `<serwis>.<namespace>.svc.cluster.local`                  | pełna nazwa DNS Serwisu          |
| `curl -H "Host: X" http://$(minikube ip)/`                | test Ingress bez `/etc/hosts`    |
| `minikube tunnel`                                         | adresy dla Serwisów LoadBalancer |
| `kubectl get ingress` · `get gateway,httproute`           | reguły ruchu HTTP                |
| `kubectl get networkpolicy` · `describe networkpolicy X`  | polityki sieciowe                |
