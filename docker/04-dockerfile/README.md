# Sekcja 4 – Budowanie własnych obrazów za pomocą Dockerfile

**Cel:** pisać Dockerfile i budować własne obrazy; dodatkowo: ENTRYPOINT vs CMD, skrypt startowy i sygnały.

## Pliki w katalogu

| Plik                                                                                 | Do czego                                                                                                                       |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| [Dockerfile](Dockerfile) · [index.html](index.html) · [.dockerignore](.dockerignore) | obraz Apache na Ubuntu 20.04 – przykład z sekcji 4                                                                             |
| [build.sh](build.sh)                                                                 | buduje `moj-apache:1.0` i tag `ubuntu_apache` (potrzebne w sekcjach 5, 8 i w ćwiczeniu IV)                                     |
| [entrypoint-cmd/](entrypoint-cmd/)                                                   | dodatkowo: ENTRYPOINT i CMD w trzech krokach (`entrypoint-cmd.sh`) – samo CMD, ENTRYPOINT + CMD, skrypt startowy z `exec "$@"` |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Ubuntu 20.04** – wersja z materiałów ALX. Nie ma już standardowego wsparcia, ale obraz i pakiety nadal są dostępne. W nowych projektach użyj `ubuntu:24.04` – reszta Dockerfile pozostaje bez zmian.

## Ćwiczenie II – modyfikacja Dockerfile (ok. 15 min)

Ćwiczenie z sekcji 9 materiałów: [../09-cwiczenia/README.md#ćwiczenie-ii--modyfikacja-dockerfile](../09-cwiczenia/README.md#ćwiczenie-ii--modyfikacja-dockerfile).

## Lab – konteneryzacja notes-api (ok. 30 min, dodatkowo – poza materiałami ALX)

Aplikacja domyślnie korzysta z bazy danych (Node.js – PostgreSQL, Python – MariaDB), której w tej sekcji jeszcze nie uruchamiamy – bazę dodamy w sekcji 8 (Docker Compose). Dlatego w kroku 3 aplikacja działa, ale zgłasza brak bazy, a w kroku 4 budujemy wariant, który zapisuje notatki w pliku. Pracuj w katalogu [students/app](../../app-node/) (Node.js) albo – jeśli wolisz Pythona – [students/app-python](../../app-python/) (FastAPI, ta sama aplikacja, opis wariantu na końcu sekcji).

1. Przejrzyj [src/server.ts](../../app-node/src/server.ts) i [package.json](../../app-node/package.json): port, budowanie (`npm run build`), uruchamianie (`node dist/server.js`), zmienne środowiskowe.
2. Napisz własny Dockerfile (bez podglądania), potem porównaj z [Dockerfile.simple](../../app-node/Dockerfile.simple).
3. Zbuduj obraz i uruchom go bez bazy danych:

   ```bash
   docker build -t notes-api:simple -f Dockerfile.simple .
   docker run -d --name notes -p 8000:3000 notes-api:simple
   curl http://localhost:8000/
   curl http://localhost:8000/readyz
   docker image ls notes-api
   docker rm -f notes
   ```

4. Zbuduj wariant bez bazy danych. [Dockerfile.simple](../../app-node/Dockerfile.simple) ma na końcu `ARG STORAGE=postgres` i `ENV STORAGE=${STORAGE}` – wartość podajesz przy budowaniu:

   ```bash
   docker build --build-arg STORAGE=json -t notes-api:json -f Dockerfile.simple .
   docker run -d --name notes -p 8000:3000 notes-api:json
   curl http://localhost:8000/
   curl -X POST -H 'Content-Type: application/json' -d '{"text":"Pierwsza notatka"}' http://localhost:8000/notes
   curl http://localhost:8000/notes
   docker exec notes cat data/notes.json
   docker rm -f notes
   ```

**Oczekiwany wynik:** w kroku 3 `/` odpowiada z `"storage":"postgres"`, a `/readyz` zwraca `{"ready":false}` (kod **503**) – aplikacja działa, ale nie ma bazy (wersja Python pokazuje `"storage":"mariadb"`). Obraz ma ok. 1,2 GB – zmniejszymy go w sekcji 10 (multi-stage), a kolejność instrukcji poprawimy w sekcji 12 (cache). W kroku 4 `/` pokazuje `"storage":"json"`, `/readyz` zwraca **200**, a notatka trafia do pliku `/app/data/notes.json` w kontenerze i znika razem z kontenerem (trwałe dane – woluminy w sekcji 6).

**Wariant Python:** w [students/app-python](../../app-python/) przejrzyj [src/main.py](../../app-python/src/main.py) i [requirements.txt](../../app-python/requirements.txt), napisz własny Dockerfile i porównaj z [Dockerfile.simple](../../app-python/Dockerfile.simple). Aplikacja nasłuchuje na porcie 8000, polecenia są takie same jak wyżej, zmieniają się tylko nazwa obrazu i port:

```bash
docker build --build-arg STORAGE=json -t notes-api-python:json -f Dockerfile.simple .
docker run -d --name notes -p 8000:8000 notes-api-python:json
```
