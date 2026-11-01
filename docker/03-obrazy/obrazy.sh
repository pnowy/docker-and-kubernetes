#!/usr/bin/env bash
# Sekcja 3 – Zarządzanie obrazami. Wykonuj polecenia pojedynczo i obserwuj wynik.

# Wyszukiwanie obrazów w Docker Hub
docker search ubuntu
docker search --filter=stars=100 nginx   # Tylko wysoko oceniane

# Pobieranie obrazu
docker pull ubuntu            # Najnowsza wersja (tag 'latest') – zmienia się w czasie!
docker pull ubuntu:20.04      # Konkretna wersja
docker pull ubuntu:22.04      # Ubuntu 22.04 LTS

# Listowanie pobranych obrazów
docker images                 # to samo co: docker image ls
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Inspekcja obrazu (szczegóły, warstwy, konfiguracja)
docker inspect ubuntu:20.04
docker history ubuntu:20.04   # Historia warstw

# Tagowanie obrazu – tag to dodatkowa nazwa tego samego obrazu (to samo ID)
docker tag ubuntu:20.04 moje-ubuntu:1.0
docker tag ubuntu:20.04 mojrejestr.example.com/moje-ubuntu:1.0
docker images --filter reference='*ubuntu*'
# Po sekcji 4 (obraz moj-apache:1.0 z ../04-dockerfile/build.sh) – polecenia z materiałów:
#   docker tag moj-apache:1.0 moj-apache:latest
#   docker tag moj-apache:1.0 mojrejestr.example.com/moj-apache:1.0

# Publikowanie obrazu do rejestru – zamień "mojnazwa" na swój login z Docker Hub
# docker login                                 # Logowanie do Docker Hub
# docker tag moj-apache:1.0 mojnazwa/moj-apache:1.0
# docker push mojnazwa/moj-apache:1.0          # Publikacja

# Usuwanie obrazu – tylko gdy nie jest używany przez żaden kontener
docker rmi moje-ubuntu:1.0 mojrejestr.example.com/moje-ubuntu:1.0   # usuwa tylko tagi
docker rmi ubuntu:22.04
docker image prune        # Usuń obrazy bez tagu (dangling)
# docker image prune -a   # Usuń wszystkie obrazy bez uruchomionych kontenerów

# --- Dodatkowo: digest i architektury ---
docker image inspect -f '{{json .RepoDigests}}' ubuntu:20.04  # digest = niezmienny identyfikator treści
docker buildx imagetools inspect ubuntu:20.04                 # manifest list: warianty dla architektur (bez pobierania)
docker system df                                              # ile miejsca zajmują obrazy, kontenery, woluminy, cache
