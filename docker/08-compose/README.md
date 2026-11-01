# Sekcja 8 – Docker Compose: orkiestracja wielu kontenerów

**Cel:** opisywać aplikację wielokontenerową w jednym pliku YAML i zarządzać nią jednym poleceniem.
**Wymaga:** Dockerfile z sekcji 4 ([../04-dockerfile](../04-dockerfile/)) – Compose sam zbuduje z niego obraz.

## Pliki w katalogu

| Plik                                         | Do czego                                                                                             |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [compose.yaml](compose.yaml) · [src/](src/)  | przykład z sekcji 8: Apache (`web`) + MariaDB (`db`), wolumin i sieć                                 |
| [compose.sh](compose.sh)                     | podstawowe polecenia `docker compose`                                                                |
| [compose-aplikacja.sh](compose-aplikacja.sh) | lab: notes-api w Pythonie + MariaDB ([../../app-python/compose.yaml](../../app-python/compose.yaml)) |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:** plik nazywa się `compose.yaml` (starsza nazwa `docker-compose.yml` nadal działa), bez linii `version: '3.8'` – w Compose v2 to pole jest przestarzałe i powoduje ostrzeżenie. `build: .` z materiałów zakłada, że Dockerfile leży obok pliku Compose – tu wskazuje katalog `../04-dockerfile`.

## Lab – aplikacja z bazą danych (ok. 30 min)

W katalogu [app-python/](../../app-python/), z plikiem [compose.yaml](../../app-python/compose.yaml) – ten sam układ co w przykładzie z materiałów, tylko zamiast Apache jest notes-api w Pythonie (FastAPI):

1. Przejrzyj plik: dwa serwisy (`db` – MariaDB, `api` – notes-api budowane z `Dockerfile` obok), wolumin `db-data`, sieć `app-network`. Jak `api` znajduje bazę?
2. Uruchom stos (`docker compose up -d --build`), sprawdź `ps` i logi serwisu `api`.
3. Dodaj notatkę (`POST /notes` na porcie 8000) i odczytaj listę.
4. Zatrzymaj i usuń stos (`down`), uruchom ponownie (`up -d`) – czy notatka nadal jest?
5. Zatrzymaj tylko serwis `db` (`stop db`) i sprawdź `/readyz`, potem uruchom go z powrotem (`start db`).

**Oczekiwany wynik:** `api` łączy się z bazą pod nazwą serwisu `db` (w logach najpierw „Baza niedostępna” – MariaDB jeszcze startuje – a po pierwszym żądaniu „Połączono z bazą danych”); notatka przetrwała `down` (wolumin `db-data`); `/readyz` bez bazy zwraca **503**.

Sprzątanie (z usunięciem danych): `docker compose down -v`.

<details>
<summary><strong>Rozwiązanie</strong></summary>

Zobacz [compose-aplikacja.sh](compose-aplikacja.sh). Zaawansowana wersja aplikacji z bazą – zmienne z `.env`, healthcheck, sekrety, profile – jest w sekcji 13 (wersja Node.js z PostgreSQL, [app-node/compose.yaml](../../app-node/compose.yaml)).

</details>

## Ściąga

| Polecenie                      | Opis                                 |
| ------------------------------ | ------------------------------------ |
| `docker compose up -d`         | uruchom wszystkie serwisy w tle      |
| `docker compose down [-v]`     | zatrzymaj i usuń (z `-v` – woluminy) |
| `docker compose ps`            | status serwisów                      |
| `docker compose logs -f web`   | logi serwisu na żywo                 |
| `docker compose exec web bash` | powłoka w serwisie                   |
| `docker compose build`         | zbuduj obrazy                        |
| `docker compose restart`       | restart serwisów                     |
