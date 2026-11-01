# Checklista weryfikacji Dockerfile i plików Compose wygenerowanych przez AI

AI przyspiesza pisanie konfiguracji, ale odpowiada za nią osoba, która ją wdraża. Każdy wygenerowany plik przejdź według listy, a potem sprawdź narzędziami.

## Lista kontrolna

| #   | Sprawdź                                                             | Błąd w [wygenerowany/Dockerfile](wygenerowany/Dockerfile) | Poprawnie, np. [app-node/Dockerfile](../../app-node/Dockerfile) |
| --- | ------------------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------------- |
| 1   | Czy tag obrazu bazowego istnieje i jest przypięty?                  | `node:latest`                                             | `node:24-slim` lub digest `@sha256:…`                           |
| 2   | Czy obraz końcowy nie zawiera narzędzi build i zależności dev?      | jeden etap, pełny obraz `node`                            | multi-stage, `npm ci --omit=dev`                                |
| 3   | Czy kolejność instrukcji wykorzystuje cache?                        | `COPY . .` przed instalacją zależności                    | `COPY package*.json` → `npm ci` → `COPY src/`                   |
| 4   | Czy instalacja jest powtarzalna?                                    | `npm install`                                             | `npm ci` z `package-lock.json`                                  |
| 5   | Czy w obrazie nie ma sekretów?                                      | `ENV PGPASSWORD=…`                                        | hasło w runtime: zmienna, plik sekretu, K8s Secret              |
| 6   | Czy proces działa jako użytkownik bez uprawnień root?               | brak `USER`                                               | `USER node`                                                     |
| 7   | Czy `EXPOSE` zgadza się z portem aplikacji?                         | `8080`, a aplikacja słucha na `3000`                      | `EXPOSE 3000`                                                   |
| 8   | Czy `CMD`/`ENTRYPOINT` są w formie exec, a proces dostaje SIGTERM?  | `CMD npm start` – powłoka i npm jako PID 1                | `CMD ["node", "dist/server.js"]`                                |
| 9   | Czy istnieje `.dockerignore`?                                       | brak – `node_modules`, `.env`, `.git` trafiają do obrazu  | [app-node/.dockerignore](../../app-node/.dockerignore)          |
| 10  | Czy nie ma halucynacji: nieistniejących flag, instrukcji, pakietów? | –                                                         | porównaj z dokumentacją, uruchom build                          |

## Weryfikacja narzędziami

```bash
docker build --check -f wygenerowany/Dockerfile ../../app-node      # reguły BuildKit: forma exec, sekrety w ENV/ARG
docker run --rm -i hadolint/hadolint < wygenerowany/Dockerfile # linter dobrych praktyk Dockerfile
docker scout quickview <obraz>                                 # podatności obrazu bazowego i zależności
docker compose config                                          # walidacja wygenerowanego compose.yaml
```

## Dobre praktyki pracy z AI

- Podawaj kontekst: pliki projektu, wersje i wymagania (jak w [prompt.md](prompt.md)), a nie tylko „napisz Dockerfile”.
- Proś o wyjaśnienie decyzji i wskazanie niepewności.
- Nie wklejaj do zewnętrznych narzędzi haseł, tokenów ani kodu objętego tajemnicą firmy.
- Każdy wygenerowany plik zbuduj, uruchom i przetestuj — tak samo jak kod napisany ręcznie.
