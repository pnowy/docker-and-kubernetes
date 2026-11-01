# Sekcja 7 – Sieci w Dockerze

**Cel:** łączyć kontenery we własnej sieci i odwoływać się do nich po nazwie (wbudowany DNS); publikować porty.

## Pliki w katalogu

| Plik                 | Do czego                                                                                                                             |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| [sieci.sh](sieci.sh) | polecenia z sekcji 7: sieci bridge/host/none, sieć użytkownika, komunikacja po nazwach, connect/disconnect; dodatkowo aliasy i porty |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku. W materiałach obrazy `backend-image` i `frontend-image` są przykładowe – w skrypcie zastąpiono je publicznymi `httpd:2.4` i `nginx:1.29`.

**Domyślna sieć:** `docker run` bez `--network` podłącza kontener do sieci o nazwie `bridge` (interfejs `docker0` na hoście). W niej **nie działa DNS po nazwach kontenerów** – działa tylko w sieciach tworzonych poleceniem `docker network create` (one też domyślnie używają sterownika `bridge`) oraz w sieciach Docker Compose.

## Ćwiczenie V – sieć wielokontenerowa (ok. 15 min)

Ćwiczenie z sekcji 9 materiałów: [../09-cwiczenia/README.md#ćwiczenie-v--sieć-wielokontenerowa](../09-cwiczenia/README.md#ćwiczenie-v--sieć-wielokontenerowa).

## Ściąga

| Polecenie                                       | Opis                                  |
| ----------------------------------------------- | ------------------------------------- |
| `docker network ls` · `inspect X` · `rm X`      | zarządzanie sieciami                  |
| `docker network create X`                       | nowa sieć (sterownik bridge, z DNS)   |
| `docker run --network X --name Y …`             | kontener w sieci – osiągalny jako `Y` |
| `docker network connect X Y` · `disconnect X Y` | podłączenie / odłączenie kontenera    |
| `-p 8080:80` · `-p 127.0.0.1:8080:80` · `-P`    | publikowanie portów                   |
