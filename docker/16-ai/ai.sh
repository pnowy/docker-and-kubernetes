#!/usr/bin/env bash
# Sekcja 16 – AI w pracy z Dockerem: docker init i weryfikacja wygenerowanych plików
cd "$(dirname "$0")" || exit 1

# --- docker init – szablon Dockerfile, compose.yaml i .dockerignore dla wykrytego języka (interaktywny) ---
# mkdir /tmp/init-demo && cp -r ../../app-node/package.json ../../app-node/package-lock.json ../../app-node/tsconfig.json ../../app-node/src /tmp/init-demo/
# cd /tmp/init-demo && docker init          # odpowiedzi: Node, wersja 24, npm, "npm start", port 3000

# --- Weryfikacja Dockerfile wygenerowanego przez AI ---
docker build --check -f wygenerowany/Dockerfile ../../app-node      # build checks: forma shell, sekret w ENV
docker run --rm -i hadolint/hadolint < wygenerowany/Dockerfile # linter: latest, npm install, brak USER…

# --- Porównanie z poprawioną wersją ---
docker build --check ../../app-node                                 # brak ostrzeżeń
docker build -q -t notes-ai -f wygenerowany/Dockerfile ../../app-node > /dev/null
docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' notes-ai
docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' notes-api:1.0.0
docker run --rm notes-ai whoami                              # root
docker history --no-trunc notes-ai | grep -o 'PGPASSWORD=[^ ]*'   # hasło zapisane w obrazie
docker rmi notes-ai

# --- Ask Gordon – asystent AI w Docker Desktop (Settings → AI) ---
# docker ai "Dlaczego mój kontener kończy się kodem 137?"
# docker ai "Co można poprawić w pliku wygenerowany/Dockerfile?"
