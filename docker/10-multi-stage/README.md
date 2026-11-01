# Sekcja 10 – Multi-stage builds

**Cel:** budować małe obrazy produkcyjne – narzędzia do budowania zostają w etapie `builder`, do obrazu końcowego trafia tylko wynik.

## Pliki w katalogu

| Plik                                           | Do czego                                                                               |
| ---------------------------------------------- | -------------------------------------------------------------------------------------- |
| [fastapi/](fastapi/)                           | przykład z sekcji 10: aplikacja Python/FastAPI, etapy `builder` + runtime (`build.sh`) |
| [multi-stage.sh](multi-stage.sh)               | notes-api: `Dockerfile.simple` (1,2 GB) → `Dockerfile` multi-stage (250 MB)            |
| [multi-stage-python.sh](multi-stage-python.sh) | dodatkowo: notes-api w Pythonie – `python:3.12` (1,2 GB) → multi-stage (170 MB)        |
| [obrazy-bazowe.sh](obrazy-bazowe.sh)           | dodatkowo: porównanie obrazów bazowych Node.js 24 (pełny, slim, alpine, distroless)    |
| [build-secrets/](build-secrets/)               | dodatkowo: sekret w `ARG` vs `RUN --mount=type=secret` (`build-secrets.sh`)            |
| [multi-platform.sh](multi-platform.sh)         | dodatkowo: obraz amd64 + arm64 z `docker buildx`                                       |
| [inne-jezyki/](inne-jezyki/)                   | dodatkowo: te same zasady dla Pythona (Flask) i Javy (Spring Boot)                     |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnica względem materiałów ALX:** w Dockerfile z materiałów komentarze `# tylko zależności, bez pip` i `# nie root!` stoją na końcu linii `COPY` i `USER`. Dockerfile nie obsługuje komentarzy na końcu linii – build kończy się błędem, dlatego w [fastapi/Dockerfile](fastapi/Dockerfile) są w osobnych liniach.

## Do samodzielnego sprawdzenia (ok. 15 min)

1. Zbuduj i uruchom przykład FastAPI według [fastapi/build.sh](fastapi/build.sh). Sprawdź, jako jaki użytkownik działa proces.
2. Porównaj rozmiar obrazu notes-api z sekcji 4 (`notes-api:simple`) z wersją multi-stage – kroki w [multi-stage.sh](multi-stage.sh).
3. Dodatkowo: to samo dla wersji w Pythonie – [multi-stage-python.sh](multi-stage-python.sh). Porównaj [app-python/Dockerfile](../../app-python/Dockerfile) z przykładem FastAPI z materiałów – co jest wspólne, a co doszło?

**Oczekiwany wynik:** FastAPI odpowiada `{"message":"Hello ALX",…}` i działa jako `nobody`; `notes-api:1.0.0` (multi-stage) ma ok. 250 MB zamiast 1,2 GB i działa jako użytkownik `node`. `notes-api-python:1.0.0` ma ok. 170 MB zamiast 1,2 GB i działa jako `app`; zależności instaluje tak samo jak przykład FastAPI (`pip install --prefix=/install`, potem `COPY` do `/usr/local`), a dodatkowo ma własnego użytkownika `app` i `HEALTHCHECK`.
