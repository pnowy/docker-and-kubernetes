# Sekcja 6 – Woluminy: trwałe przechowywanie danych

**Cel:** przechowywać dane poza warstwą zapisu kontenera: named volume, bind mount, tmpfs; dodatkowo kopia zapasowa i wolumin NFS.
**Wymaga:** obrazu `moj-apache:1.0` (bind mount) i `ubuntu_apache` (ćwiczenie IV) – buduje je [../04-dockerfile/build.sh](../04-dockerfile/build.sh).

## Pliki w katalogu

| Plik                               | Do czego                                                                                                                |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| [woluminy.sh](woluminy.sh)         | polecenia z sekcji 6: volume create/ls/inspect/rm, named volume, bind mount, `--mount`, tmpfs; dodatkowo kopia zapasowa |
| [woluminy-nfs.sh](woluminy-nfs.sh) | dodatkowo: wolumin zdalny NFS (serwer NFS w kontenerze)                                                                 |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Ćwiczenie IV – woluminy i trwałość danych (ok. 15 min)

Ćwiczenie z sekcji 9 materiałów: [../09-cwiczenia/README.md#ćwiczenie-iv--woluminy-i-trwałość-danych](../09-cwiczenia/README.md#ćwiczenie-iv--woluminy-i-trwałość-danych).

## Ściąga

| Polecenie                                              | Opis                                       |
| ------------------------------------------------------ | ------------------------------------------ |
| `docker volume create X` · `ls` · `inspect X` · `rm X` | zarządzanie woluminami                     |
| `docker volume prune`                                  | usuń nieużywane woluminy                   |
| `-v wolumin:/ścieżka`                                  | named volume                               |
| `-v $(pwd)/src:/ścieżka[:ro]`                          | bind mount katalogu hosta (`:ro` – odczyt) |
| `--mount source=X,target=/ścieżka`                     | ten sam montaż w czytelniejszej składni    |
| `--tmpfs /ścieżka`                                     | dane tylko w pamięci RAM                   |
