# Sekcja 12 – Optymalizacja rozmiaru obrazów

**Cel:** układać instrukcje Dockerfile tak, żeby cache buildera przyspieszał przebudowy, i diagnozować, co zajmuje miejsce w obrazie.

## Pliki w katalogu

| Plik                                 | Do czego                                                                                                                                       |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [optymalizacja.sh](optymalizacja.sh) | przebudowa po zmianie kodu: `Dockerfile.simple` (kod przed zależnościami) vs `Dockerfile.cached`; `docker history`, `dive`, `docker system df` |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Do samodzielnego sprawdzenia (ok. 10 min)

W katalogu [app-node/](../../app-node/) porównaj [Dockerfile.simple](../../app-node/Dockerfile.simple) z [Dockerfile.cached](../../app-node/Dockerfile.cached) – mają te same instrukcje w innej kolejności.

1. Zbuduj oba obrazy (`docker build -t notes-api:simple -f Dockerfile.simple .` i `docker build -t notes-api:cached -f Dockerfile.cached .`).
2. Dopisz komentarz na końcu `src/server.ts` (np. `echo "// zmiana" >> src/server.ts`) i zbuduj oba obrazy ponownie z `--progress=plain`.
3. Przy którym pliku `npm ci` wykonało się od nowa, a przy którym jest `CACHED`?
4. Przywróć plik: `git checkout src/server.ts`.

**Oczekiwany wynik:** w `Dockerfile.simple` zmiana kodu unieważnia `COPY . .` i wszystkie kolejne kroki – `npm ci` wykonuje się od nowa; w `Dockerfile.cached` kroki z `package.json` i `npm ci` są `CACHED`, przebudowuje się tylko kod.

## Ściąga

| Polecenie                       | Opis                                                  |
| ------------------------------- | ----------------------------------------------------- |
| `docker history obraz:tag`      | rozmiar każdej warstwy                                |
| `dive obraz:tag`                | interaktywny eksplorator warstw (`brew install dive`) |
| `docker system df`              | zużycie dysku: obrazy, kontenery, woluminy, cache     |
| `docker build --progress=plain` | pełny log budowania – widać `CACHED`                  |
