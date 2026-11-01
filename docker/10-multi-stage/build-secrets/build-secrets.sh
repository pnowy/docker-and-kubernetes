#!/usr/bin/env bash
# Sekcja 10 – Sekrety podczas budowania: ARG vs RUN --mount=type=secret
cd "$(dirname "$0")" || exit 1

export TOKEN_SEKRET=token-z-secret-456
docker build --progress=plain --no-cache \
  --build-arg API_TOKEN=token-z-arg-123 \
  --secret id=api_token,env=TOKEN_SEKRET \
  -t demo-sekrety . 2>&1 | grep -E 'Sekret dostępny|WARN'

# Token przekazany przez ARG jest widoczny w historii obrazu:
docker history --no-trunc demo-sekrety | grep -o 'API_TOKEN=[^ ]*' | sort -u   # API_TOKEN=token-z-arg-123
# Sekret z --secret nie występuje nigdzie w obrazie (0 wystąpień):
docker history --no-trunc demo-sekrety | grep -c token-z-secret || true
docker rmi demo-sekrety
