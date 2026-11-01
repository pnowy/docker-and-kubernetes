# Sekcja 13 (dodatek) – Skalowanie i load balancing

**Cel:** uruchomić kilka replik API za load balancerem i porównać Nginx, HAProxy i Traefik.
**Wymaga:** obrazu `notes-api:1.0.0` z sekcji 10 – `docker build -t notes-api:1.0.0 .` w katalogu [app-node/](../../../app-node/).

## Pliki w katalogu

| Plik                                                                | Do czego                                                                  |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| [compose.yaml](compose.yaml) · [api-repliki.yaml](api-repliki.yaml) | baza + 3 repliki notes-api (dołączone z `../../../app-node`) i trzy proxy |
| [nginx/](nginx/) · [haproxy/](haproxy/)                             | konfiguracje Nginx i HAProxy                                              |
| [load-balancing.sh](load-balancing.sh)                              | rozwiązanie ćwiczenia 13A                                                 |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Ćwiczenie 13A (dodatkowe) – load balancing (ok. 25 min)

1. Uruchom stos: `docker compose up -d --wait`.
2. Sprawdź rozkład ruchu dla portów 8080 (Nginx), 8085 (HAProxy) i 8088 (Traefik) – pętla `curl` z `uniq -c`.
3. Przeskaluj API do 5 replik i obserwuj statystyki HAProxy (:8404) i dashboard Traefika (:8089).
4. Zatrzymaj (`docker stop lb-api-2`) i zamroź (`docker pause lb-api-3`) replikę – porównaj zachowanie proxy (`curl -w '%{time_total}'`).
5. Dla chętnych: w HAProxy zmień `balance roundrobin` na `balance source`.
6. Sprzątanie: `docker compose down -v`.

**Oczekiwany wynik:** ruch rozkłada się mniej więcej równo między repliki; po awarii repliki proxy omijają ją (zamrożona replika daje opóźnienia do czasu wykrycia).

<details>
<summary><strong>Rozwiązanie</strong></summary>

Zobacz [load-balancing.sh](load-balancing.sh).

</details>
