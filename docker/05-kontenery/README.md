# Sekcja 5 – Zarządzanie kontenerami

**Cel:** swobodnie uruchamiać, podglądać, zmieniać i sprzątać kontenery, oraz rozumieć, co dzieje się z danymi w kontenerze.
**Czas:** ok. 15 min ćwiczenia III + do 20 min ćwiczeń dodatkowych (5A ok. 15 min, 5B ok. 5 min).

## Pliki w katalogu

| Plik                                       | Do czego                                                                                               |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| [kontenery.sh](kontenery.sh)               | polecenia z sekcji 5: run, ps, stop/start, logs, exec, cp, inspect (obraz `moj-apache:1.0` z sekcji 4) |
| [restart-i-limity.sh](restart-i-limity.sh) | demo: polityki restartu, limity, OOM                                                                   |
| [logi.sh](logi.sh)                         | demo: sterowniki logowania i rotacja                                                                   |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Ćwiczenie III – uruchamianie kontenerów MariaDB (ok. 15 min)

Ćwiczenie z sekcji 9 materiałów: [../09-cwiczenia/README.md#ćwiczenie-iii--uruchamianie-kontenerów-mariadb](../09-cwiczenia/README.md#ćwiczenie-iii--uruchamianie-kontenerów-mariadb).

## Ćwiczenie 5A (dodatkowe) – własna strona w nginx (ok. 15 min)

1. Uruchom w tle kontener `www` z obrazu `nginx:1.29`, z portem hosta **8080** podpiętym do portu **80** kontenera.
2. Otwórz <http://localhost:8080> – powinna być strona „Welcome to nginx!”.
3. Utwórz na hoście plik `index.html` z treścią `<h1>Witaj ALX</h1>` i skopiuj go do kontenera jako `/usr/share/nginx/html/index.html`. Odśwież stronę.
4. Sprawdź w logach kontenera, że widać Twoje żądanie `GET /`.
5. Wejdź do kontenera powłoką i obejrzyj `/etc/nginx/conf.d/default.conf`. Wyjdź.
6. Wyświetl, które pliki zmieniły się w kontenerze względem obrazu.
7. Zatrzymaj i ponownie uruchom kontener. Czy Twoja strona nadal jest?
8. Usuń kontener i uruchom nowy z tymi samymi parametrami. Czy Twoja strona nadal jest?

**Oczekiwany wynik:** po kroku 7 strona „Witaj ALX” zostaje, po kroku 8 wraca „Welcome to nginx!”.

<details>
<summary><strong>Rozwiązanie 5A</strong></summary>

```bash
docker run -d --name www -p 8080:80 nginx:1.29
curl -s http://localhost:8080 | grep title          # <title>Welcome to nginx!</title>

echo '<h1>Witaj ALX</h1>' > index.html
docker cp index.html www:/usr/share/nginx/html/index.html
curl -s http://localhost:8080                       # <h1>Witaj ALX</h1>

docker logs --tail 1 www                            # "GET / HTTP/1.1" 200 ...
docker exec -it www bash                            # cat /etc/nginx/conf.d/default.conf; exit
docker diff www                                     # C /usr/share/nginx/html/index.html, A /run/nginx.pid ...

docker stop www && docker start www
curl -s http://localhost:8080                       # <h1>Witaj ALX</h1> – warstwa zapisu przetrwała

docker rm -f www
docker run -d --name www -p 8080:80 nginx:1.29
curl -s http://localhost:8080 | grep title          # Welcome to nginx! – nowy kontener = nowa warstwa zapisu
docker rm -f www && rm index.html
```

`docker diff`: **A** – plik dodany, **C** – zmieniony, **D** – usunięty. Dane w warstwie zapisu żyją tak długo jak kontener – trwałe dane trzymamy w woluminach (sekcja 6).

</details>

## Ćwiczenie 5B (dodatkowe) – restart i limity (ok. 5 min)

1. Uruchom `busybox:1.37` z poleceniem `sh -c 'echo start; sleep 1; exit 1'` i polityką restartu, która ponowi start maksymalnie 3 razy. Po 15 s sprawdź liczbę restartów i logi.
2. Uruchom `busybox:1.37` z limitem pamięci 64 MB i poleceniem `sh -c 'x=a; while true; do x=$x$x; done'` (napis podwaja się w nieskończoność). Jak zakończył się kontener?

**Oczekiwany wynik:** `RestartCount` = 3 i 4 linie `start` w logach; `OOMKilled=true`, kod wyjścia **137**.

<details>
<summary><strong>Rozwiązanie 5B</strong></summary>

Zobacz [restart-i-limity.sh](restart-i-limity.sh).

</details>

## Ściąga

| Polecenie                                             | Opis                             |
| ----------------------------------------------------- | -------------------------------- |
| `docker run -d --name X -p H:K obraz`                 | uruchom w tle, opublikuj port    |
| `docker run -it --rm obraz sh`                        | interaktywnie, usuń po wyjściu   |
| `docker ps -a`                                        | wszystkie kontenery              |
| `docker logs -f --tail 20 X`                          | logi na żywo                     |
| `docker exec -it X sh`                                | powłoka w działającym kontenerze |
| `docker cp plik X:/ścieżka`                           | kopiowanie host → kontener       |
| `docker inspect -f '{{.State.Status}}' X`             | pojedyncze pole                  |
| `docker diff X` · `docker top X` · `docker stats`     | zmiany plików · procesy · zasoby |
| `docker stop X` · `docker start X` · `docker rm -f X` | cykl życia                       |
