# Prompt: Dockerfile dla aplikacji notes-api

Przykładowy prompt do asystenta AI (ChatGPT, Claude, Copilot, Gordon). Wklej go razem z plikami `package.json`, `tsconfig.json` i `src/server.ts` z katalogu [app-node/](../../app-node/).

```text
Przygotuj produkcyjny Dockerfile dla aplikacji Node.js 24 + TypeScript (Express 5, pliki poniżej).

Wymagania:
- multi-stage build: kompilacja TypeScript (npm run build) w osobnym etapie,
  do obrazu końcowego tylko dist/ i zależności produkcyjne (npm ci --omit=dev)
- obraz bazowy node:24-slim z konkretnym tagiem, bez "latest"
- kolejność instrukcji przyjazna dla cache (package*.json i npm ci przed kodem)
- cache npm przez RUN --mount=type=cache
- proces uruchamiany jako użytkownik node, nie root
- CMD w formie exec (JSON), aplikacja nasłuchuje na porcie 3000
- HEALTHCHECK na endpoint /healthz bez instalowania curl
- żadnych haseł ani tokenów w ARG/ENV – hasło do bazy przychodzi w runtime
- osobno plik .dockerignore

Wyjaśnij każdą decyzję jednym zdaniem i wskaż, czego nie jesteś pewien.
```

Krótki prompt bez wymagań („napisz Dockerfile dla tej aplikacji”) zwykle daje wynik podobny do [wygenerowany/Dockerfile](wygenerowany/Dockerfile) — sprawdź go według [checklisty](checklista.md).
