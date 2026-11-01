# Sekcja 3 – Zarządzanie obrazami

**Cel:** wyszukiwać, pobierać, tagować, badać i usuwać obrazy; rozumieć warstwy, tag i digest.

## Pliki w katalogu

| Plik                     | Do czego                                                                     |
| ------------------------ | ---------------------------------------------------------------------------- |
| [obrazy.sh](obrazy.sh)   | polecenia z sekcji 3: search, pull, images, inspect, history, tag, push, rmi |
| [warstwy.sh](warstwy.sh) | dodatkowo: warstwy obrazu i copy-on-write (`docker diff`, `docker ps -s`)    |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku. `docker image prune` pyta o potwierdzenie (`y`).

## Ćwiczenie I – pobieranie i inspekcja obrazu MariaDB (ok. 10 min)

Ćwiczenie z sekcji 9 materiałów: [../09-cwiczenia/README.md#ćwiczenie-i--pobieranie-i-inspekcja-obrazu-mariadb](../09-cwiczenia/README.md#ćwiczenie-i--pobieranie-i-inspekcja-obrazu-mariadb).

## Dodatkowe pytania do ćwiczenia I

1. Jakie porty, woluminy i polecenie startowe definiuje obraz? Podpowiedź: `docker image inspect -f '{{.Config.ExposedPorts}} {{.Config.Volumes}} {{.Config.Cmd}}' mariadb`.
2. Która instrukcja dodała najwięcej danych? Podpowiedź: `docker history --format '{{.Size}}\t{{.CreatedBy}}' mariadb | sort -h -r | head -3`.
3. Jaki jest digest obrazu? Podpowiedź: `docker image inspect -f '{{index .RepoDigests 0}}' mariadb`.

**Oczekiwany wynik:** port `3306/tcp`, wolumin `/var/lib/mysql`, polecenie `mariadbd`; najwięcej danych dodaje instrukcja `RUN … apt-get install … mariadb-server`; digest w postaci `mariadb@sha256:…`. Tag (`latest`) może wskazywać różne obrazy w czasie, digest – zawsze ten sam.

## Ściąga

| Polecenie                                     | Opis                                       |
| --------------------------------------------- | ------------------------------------------ |
| `docker search --filter=stars=100 nginx`      | wyszukiwanie w Docker Hub                  |
| `docker pull ubuntu:20.04`                    | pobranie konkretnej wersji                 |
| `docker images`                               | lista obrazów (= `docker image ls`)        |
| `docker inspect ubuntu:20.04`                 | konfiguracja obrazu (JSON)                 |
| `docker history ubuntu:20.04`                 | warstwy obrazu                             |
| `docker tag obraz:1.0 rejestr/obraz:1.0`      | nowa nazwa tego samego obrazu              |
| `docker push mojnazwa/obraz:1.0`              | publikacja w rejestrze (po `docker login`) |
| `docker rmi obraz:1.0` · `docker image prune` | usunięcie obrazu · obrazów bez tagu        |
