#!/usr/bin/env bash
# Sekcja 10 – Porównanie obrazów bazowych dla tej samej platformy (Node.js 24)

for obraz in node:24 node:24-slim node:24-alpine gcr.io/distroless/nodejs24-debian13; do
  docker pull -q "$obraz" > /dev/null
done
for obraz in node:24 node:24-slim node:24-alpine gcr.io/distroless/nodejs24-debian13; do
  docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' "$obraz"
done

# Co jest w środku? Pełny obraz ma kompilatory i narzędzia, slim tylko runtime, alpine używa musl zamiast glibc
docker run --rm node:24 sh -c 'gcc --version | head -1; git --version'
docker run --rm node:24-slim sh -c 'which gcc git curl || echo "slim: brak gcc, git i curl"'
docker run --rm node:24-alpine sh -c 'ldd --version 2>&1 | head -1'      # musl libc
# distroless nie ma powłoki ani menedżera pakietów – działa tylko program z ENTRYPOINT
docker run --rm gcr.io/distroless/nodejs24-debian13 -e 'console.log("distroless: tylko node")'
docker run --rm --entrypoint sh gcr.io/distroless/nodejs24-debian13 || echo "distroless: brak powłoki"
