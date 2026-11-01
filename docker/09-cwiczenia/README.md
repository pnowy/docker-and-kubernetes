# Sekcja 9 – Ćwiczenia praktyczne

Ćwiczenia I–V z materiałów ALX, z tą samą numeracją kroków (7–24). Na zajęciach każde ćwiczenie robimy na końcu sekcji, której dotyczy. Każde ćwiczenie ma własny katalog: polecenia są w tym README, rozwiązanie w pliku `rozwiazanie.sh`, a ćwiczenie II ma dodatkowo punkt startowy (`start/`) i gotowe pliki po zmianach (`rozwiazanie/`).

| Ćwiczenie | Temat                                 | Po sekcji     | Czas   | Katalog                                                                       |
| --------- | ------------------------------------- | ------------- | ------ | ----------------------------------------------------------------------------- |
| I         | Pobieranie i inspekcja obrazu MariaDB | 3. Obrazy     | 10 min | [cwiczenie-1-obraz-mariadb/](cwiczenie-1-obraz-mariadb/)                      |
| II        | Modyfikacja Dockerfile                | 4. Dockerfile | 15 min | [cwiczenie-2-dockerfile/](cwiczenie-2-dockerfile/) – `start/`, `rozwiazanie/` |
| III       | Uruchamianie kontenerów MariaDB       | 5. Kontenery  | 15 min | [cwiczenie-3-kontenery-mariadb/](cwiczenie-3-kontenery-mariadb/)              |
| IV        | Woluminy i trwałość danych            | 6. Woluminy   | 15 min | [cwiczenie-4-woluminy/](cwiczenie-4-woluminy/)                                |
| V         | Sieć wielokontenerowa                 | 7. Sieci      | 15 min | [cwiczenie-5-siec/](cwiczenie-5-siec/)                                        |

Skrypty `rozwiazanie.sh` to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku. Polecenia w ćwiczeniach są takie jak w materiałach ALX; tam, gdzie wersja z materiałów nie działa w aktualnym Dockerze, podana jest poprawka (oznaczona **Uwaga**).

## Ćwiczenie I – Pobieranie i inspekcja obrazu MariaDB

7. Wyszukaj i pobierz obraz mariadb:

   ```bash
   docker search mariadb
   docker pull mariadb
   ```

8. Sprawdź rozmiar i szczegóły obrazu:

   ```bash
   docker images mariadb
   docker inspect mariadb
   ```

9. Sprawdź historię warstw obrazu:

   ```bash
   docker history mariadb
   ```

**Oczekiwany wynik:** obraz ma kilkaset MB; `docker inspect` pokazuje m.in. port `3306/tcp`, wolumin `/var/lib/mysql` i polecenie startowe `mariadbd`; `docker history` – listę warstw z poleceniami, które je utworzyły.

## Ćwiczenie II – Modyfikacja Dockerfile

Punkt startowy: [cwiczenie-2-dockerfile/start/](cwiczenie-2-dockerfile/start/) – Dockerfile i `index.html` z sekcji 4 przed zmianami. Pracuj w tym katalogu: `cd cwiczenie-2-dockerfile/start`. Gotowe pliki po zmianach: [cwiczenie-2-dockerfile/rozwiazanie/](cwiczenie-2-dockerfile/rozwiazanie/).

10. Zmodyfikuj Dockerfile, zmieniając maintainer:

    ```dockerfile
    LABEL maintainer="twoj.nowy@email.com"
    ```

11. Utwórz plik alx.html i dodaj go do obrazu:

    ```bash
    echo '<h1>Hello ALX</h1>' > alx.html
    ```

    W Dockerfile dodaj (pod istniejącym `COPY index.html …`):

    ```dockerfile
    COPY alx.html /var/www/html/
    ```

12. Zbuduj nowy obraz i zweryfikuj jego działanie:

    ```bash
    docker build -t moj-apache:2.0 .
    docker run -d -p 8081:80 --name test-apache moj-apache:2.0
    curl http://localhost:8081/alx.html
    ```

**Oczekiwany wynik:** `curl` zwraca `<h1>Hello ALX</h1>`.

Sprzątanie: `docker rm -f test-apache`; zmiany cofniesz w katalogu `start`: `git checkout -- . && rm alx.html`.

## Ćwiczenie III – Uruchamianie kontenerów MariaDB

13. Uruchom kontener mariadb:

    ```bash
    docker run -d --name moja-baza -e MYSQL_ROOT_PASSWORD=tajnehaslo mariadb
    ```

14. Sprawdź adres IP kontenera:

    ```bash
    docker inspect moja-baza | grep IPAddress
    ```

15. Uruchom nowy kontener z mapowaniem portu:

    ```bash
    docker run -d --name moja-baza2 -p 3306:3306 -e MYSQL_ROOT_PASSWORD=tajnehaslo mariadb
    ```

16. Uruchom powłokę w kontenerze i sprawdź procesy:

    ```bash
    docker exec -it moja-baza2 bash
    # Wewnątrz kontenera:
    ps auxf
    mariadb -u root -ptajnehaslo -e "SHOW DATABASES;"
    exit
    ```

    **Uwaga:** w materiałach ALX jest `mysql -u root …`. W aktualnym obrazie `mariadb` klient nazywa się `mariadb` – polecenie `mysql` zwraca `command not found`.

17. Sprawdź zmodyfikowane pliki w kontenerze:

    ```bash
    docker diff moja-baza2
    ```

**Oczekiwany wynik:** adres IP w rodzaju `172.17.0.x`; w `ps auxf` proces `mariadbd` z PID 1; bazy `information_schema`, `mysql`, `performance_schema`, `sys`; w `docker diff` pliki w `/run/mysqld` (litera **A** – dodany, **C** – zmieniony).

Sprzątanie: `docker rm -f moja-baza moja-baza2`.

## Ćwiczenie IV – Woluminy i trwałość danych

Wymaga obrazu `ubuntu_apache` z sekcji 4 – zbuduj go poleceniem `../04-dockerfile/build.sh` (z katalogu `09-cwiczenia`).

18. Utwórz wolumin i uruchom kontener ubuntu_apache:

    ```bash
    docker volume create www-data
    docker run -d --name moj-apache-wolumin -v www-data:/var/www/html/alx ubuntu_apache
    # Utwórz plik w woluminie na hoście
    sudo touch /var/lib/docker/volumes/www-data/_data/alx.html
    ```

    **Uwaga:** ścieżka `/var/lib/docker/volumes` istnieje tylko na Linuksie z Docker Engine. W Docker Desktop (macOS/Windows) wolumin leży w maszynie wirtualnej – utwórz plik przez kontener pomocniczy: `docker run --rm -v www-data:/data busybox touch /data/alx.html`.

19. Wejdź do kontenera, zweryfikuj pliki i zatrzymaj proces:

    ```bash
    docker exec -it moj-apache-wolumin bash
    ls /var/www/html/alx/
    ps aux | grep apache2
    kill <PID>
    ```

    Jako `<PID>` podaj numer procesu `/usr/sbin/apache2 -D FOREGROUND` uruchomionego jako `root`. Apache kończy pracę, sesja `bash` się urywa, a kontener przechodzi w stan `Exited` (`docker ps -a`).

20. Skopiuj plik do kontenera:

    ```bash
    touch kopiowanie.html
    docker cp kopiowanie.html moj-apache-wolumin:/var/www/html/
    ```

21. Usuń kontener i zweryfikuj, że wolumin przetrwał:

    ```bash
    docker rm -f moj-apache-wolumin
    docker volume ls | grep www-data
    # Wolumin nadal istnieje - dane są trwałe!
    # Uruchom nowy kontener z tym samym woluminem
    docker run -d --name nowy-apache -v www-data:/var/www/html/alx ubuntu_apache
    docker exec nowy-apache ls /var/www/html/alx/ /var/www/html/
    ```

**Oczekiwany wynik:** `docker cp` działa także na zatrzymanym kontenerze; w nowym kontenerze `alx.html` (wolumin) jest, a `kopiowanie.html` (warstwa zapisu usuniętego kontenera) – nie.

Sprzątanie: `docker rm -f nowy-apache && docker volume rm www-data && rm kopiowanie.html`.

## Ćwiczenie V – Sieć wielokontenerowa

22. Utwórz dedykowaną sieć dla aplikacji:

    ```bash
    docker network create moja-app-siec
    ```

23. Uruchom kontener z bazą danych:

    ```bash
    docker run -d --name baza --network moja-app-siec \
      -e MYSQL_ROOT_PASSWORD=secret -e MYSQL_DATABASE=testdb mariadb
    ```

24. Uruchom kontener aplikacji w tej samej sieci:

    ```bash
    docker run -it --rm --network moja-app-siec ubuntu bash
    # Wewnątrz - zainstaluj klienta MySQL i połącz się po nazwie kontenera:
    apt-get update && apt-get install -y mysql-client
    mysql -h baza -u root -psecret testdb
    ```

    W konsoli `mysql` wpisz `SELECT VERSION();`, a potem `exit`, i jeszcze raz `exit`, żeby wyjść z kontenera.

**Oczekiwany wynik:** `SELECT VERSION();` zwraca wersję MariaDB – nazwa kontenera `baza` działa jak nazwa hosta. W domyślnej sieci `bridge` (bez `--network`) to połączenie by nie zadziałało.

Sprzątanie: `docker rm -f baza && docker network rm moja-app-siec`.
