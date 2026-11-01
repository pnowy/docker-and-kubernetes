# Sekcja 13 – Docker Compose – zaawansowane wzorce

**Cel:** zmienne z pliku `.env`, nadpisywanie konfiguracji dla środowisk, healthcheck i `depends_on` z warunkiem; dodatkowo: sekrety, profile, `compose watch`, Compose na serwerze i load balancing.

## Pliki w katalogu

| Plik                                                                                                         | Do czego                                                                                                                              |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| [.env](.env) · [docker-compose.yml](docker-compose.yml) · [docker-compose.prod.yml](docker-compose.prod.yml) | przykład z sekcji 13: PostgreSQL + aplikacja FastAPI z sekcji 10, healthcheck, nadpisanie dla produkcji                               |
| [compose.sh](compose.sh)                                                                                     | polecenia z sekcji 13: `config`, `up`, scalanie plików `-f … -f …`                                                                    |
| [compose-aplikacja.sh](compose-aplikacja.sh)                                                                 | dodatkowo: notes-api w pełnej wersji ([../../app-node/compose.yaml](../../app-node/compose.yaml)) – sekrety, profile, `compose watch` |
| [compose-produkcja.sh](compose-produkcja.sh)                                                                 | dodatkowo: nadpisanie `compose.prod.yaml` – limity, rotacja logów, tylko do odczytu, izolacja sieci                                   |
| [load-balancing/](load-balancing/)                                                                           | dodatkowo: repliki notes-api za Nginx, HAProxy i Traefik                                                                              |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Port 80 w `docker-compose.prod.yml`** (jak w materiałach) bywa zajęty na komputerze uczestnika lub wymaga uprawnień – wtedy zmień `"80:8000"` na np. `"8090:8000"`.

## Do samodzielnego sprawdzenia (ok. 15 min)

1. Uruchom `docker compose config` i znajdź w wyniku wartości podstawione z [.env](.env).
2. Uruchom stos (`docker compose up -d --build`) i obserwuj `docker compose ps` – kiedy startuje `app`?
3. Sprawdź `curl http://localhost:8000/` – skąd aplikacja zna wersję?
4. Uruchom wersję produkcyjną: `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d` i sprawdź porty w `docker compose ps`.
5. Posprzątaj: `docker compose -f docker-compose.yml -f docker-compose.prod.yml down`.

**Oczekiwany wynik:** `app` startuje dopiero, gdy `db` ma status `(healthy)`; odpowiedź `{"message":"Hello ALX","version":"2.1.0"}` – wersja pochodzi z `APP_VERSION` w `.env`; w wersji produkcyjnej aplikacja jest na porcie 80 (`ports: !override` zastępuje listę portów z pliku bazowego) i ma `restart: always`.
