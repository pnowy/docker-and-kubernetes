# Sekcja 1 – Wprowadzenie do Kubernetesa

**Cel:** zobaczyć na działającym klastrze to, o czym mówi teoria: komponenty Control Plane, węzeł, Pod i pętlę „stan pożądany → stan aktualny”.
**Wymaga:** klastra minikube z [sekcji 2](../02-instalacja/README.md). Na zajęciach prowadzący pokazuje te polecenia na swoim klastrze; Ty wykonasz je po sekcji 2.

## Pliki w katalogu

| Plik                               | Do czego                                                                                |
| ---------------------------------- | --------------------------------------------------------------------------------------- |
| [architektura.sh](architektura.sh) | komponenty klastra, przepływ tworzenia Poda, samonaprawianie, `api-resources`/`explain` |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Do samodzielnego sprawdzenia (ok. 10 min, po sekcji 2)

1. Znajdź wśród Podów `kube-system` wszystkie komponenty Control Plane z materiałów (1.2). Który komponent działa na każdym węźle, a nie tylko na Control Plane?
2. Utwórz Deployment `hello` z 2 replikami i usuń jego Pody. Kto i dlaczego tworzy nowe?
3. Wypisz zdarzenia klastra i dopasuj je do kroków „Przepływu tworzenia Poda” z materiałów.

<details>
<summary><strong>Rozwiązanie</strong></summary>

Polecenia są w [architektura.sh](architektura.sh).

1. `etcd-…`, `kube-apiserver-…`, `kube-scheduler-…` i `kube-controller-manager-…` to statyczne Pody Control Plane (manifesty w `/etc/kubernetes/manifests`). Na każdym węźle działają `kube-proxy-…` i `calico-node-…` – to DaemonSety; kubelet i containerd nie są Podami, tylko usługami systemu węzła.
2. Kontroler ReplicaSet (w `kube-controller-manager`) widzi 0 z 2 pożądanych Podów i tworzy nowe; Scheduler przypisuje je do węzła, a kubelet uruchamia kontenery.
3. `Scheduled` (Scheduler zapisał węzeł w API) → `Pulling`/`Pulled` (kubelet pobiera obraz) → `Created`/`Started` (containerd uruchomił kontener).

</details>

## Ściąga

| Polecenie                                     | Opis                                 |
| --------------------------------------------- | ------------------------------------ |
| `kubectl cluster-info`                        | adres API Servera                    |
| `kubectl get nodes -o wide`                   | węzły z adresami IP i wersjami       |
| `kubectl get pods -n kube-system`             | komponenty systemowe klastra         |
| `kubectl get events --sort-by=.lastTimestamp` | zdarzenia od najstarszego            |
| `kubectl api-resources`                       | wszystkie typy obiektów i ich skróty |
| `kubectl explain pod.spec`                    | dokumentacja pól manifestu           |
