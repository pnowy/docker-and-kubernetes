# notes-api w Pythonie (FastAPI)

Ta sama aplikacja co [app-node/](../app-node/) (Node.js), napisana w Pythonie 3.12 + FastAPI: te same endpointy (`/`, `/healthz`, `/readyz`, `GET/POST /notes`) i ten sam wybór przechowywania danych przez zmienną `STORAGE` – `mariadb` (domyślnie, zmienne `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`/`DB_PASSWORD_FILE`, `DB_NAME`) albo `json` (plik `data/notes.json`, bez bazy). W odróżnieniu od wersji Node.js (PostgreSQL) korzysta z **MariaDB** – tej samej bazy co przykłady z materiałów ALX. Aplikacja nasłuchuje na porcie **8000**.

| Plik                                   | Do czego                                                                                           |
| -------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [src/main.py](src/main.py)             | API FastAPI + dwa magazyny notatek (plik JSON, MariaDB)                                            |
| [requirements.txt](requirements.txt)   | zależności: `fastapi`, `uvicorn`, `PyMySQL`                                                        |
| [Dockerfile.simple](Dockerfile.simple) | lab z sekcji 4: jeden etap na pełnym `python:3.12` (ok. 1,2 GB)                                    |
| [Dockerfile](Dockerfile)               | sekcja 10: multi-stage, zależności z etapu `builder` w `/usr/local`, użytkownik `app` (ok. 170 MB) |
| [compose.yaml](compose.yaml)           | lab z sekcji 8: API + MariaDB, wolumin `db-data`, sieć `app-network`                               |

```bash
cd app-python
docker build --build-arg STORAGE=json -t notes-api-python:json -f Dockerfile.simple .
docker run -d --name notes-py -p 8000:8000 notes-api-python:json
curl -X POST -H 'Content-Type: application/json' -d '{"text":"Pierwsza notatka"}' http://localhost:8000/notes
curl http://localhost:8000/notes
docker rm -f notes-py
```

Z bazą MariaDB (lab z sekcji 8):

```bash
cd app-python
docker compose up -d --build
curl http://localhost:8000/readyz        # {"ready":true} po kilku sekundach
docker compose down -v
```

Dokumentacja API generowana przez FastAPI: <http://localhost:8000/docs>.
