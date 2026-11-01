#!/bin/sh
# Skrypt startowy: najpierw przygotowanie, na końcu exec "$@" uruchamia CMD i oddaje mu PID 1
set -e
DATA_FILE=${DATA_FILE:-data/notes.json}

if [ "$STORAGE" = "json" ] && [ ! -f "$DATA_FILE" ]; then
  mkdir -p "$(dirname "$DATA_FILE")"
  echo "entrypoint.sh: brak $DATA_FILE – tworzę przykładową notatkę"
  printf '[{"id":1,"text":"Notatka z entrypoint.sh","created_at":"%s"}]\n' "$(date -u +%FT%TZ)" > "$DATA_FILE"
fi

echo "entrypoint.sh: uruchamiam $*"
exec "$@"
