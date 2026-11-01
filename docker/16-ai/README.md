# Sekcja 16 (dodatek) – AI w pracy z Dockerem

**Cel:** korzystać z asystentów AI i `docker init`, ale zawsze weryfikować wygenerowane pliki.

## Pliki w katalogu

| Plik                                               | Do czego                                                |
| -------------------------------------------------- | ------------------------------------------------------- |
| [prompt.md](prompt.md)                             | przykład dobrego promptu z kontekstem i wymaganiami     |
| [wygenerowany/Dockerfile](wygenerowany/Dockerfile) | typowa odpowiedź AI na krótki prompt – z błędami        |
| [checklista.md](checklista.md)                     | checklista weryfikacji Dockerfile i plików Compose      |
| [ai.sh](ai.sh)                                     | demo: `docker init` i weryfikacja wygenerowanych plików |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Ćwiczenie – znajdź błędy (ok. 10 min)

Przejrzyj [wygenerowany/Dockerfile](wygenerowany/Dockerfile) według [checklista.md](checklista.md) i wypisz wszystkie problemy. Potem porównaj z [../../app-node/Dockerfile](../../app-node/Dockerfile).

**Oczekiwany wynik:** co najmniej 6 problemów, m.in. `node:latest`, jeden etap, `npm install`, uruchamianie jako root, sekret w `ENV`, forma shell w `CMD`, port w `EXPOSE` niezgodny z aplikacją (3000).

## Docker Skills – daj agentowi wiedzę o Dockerze

[Docker Skills](https://docs.docker.com/ai/skills/install/) to oficjalne instrukcje dla agentów AI: agent wczytuje je przy zadaniach związanych z Dockerem, m.in. przy pisaniu Dockerfile i Compose, a przed poleceniami usuwającymi dane dostaje ostrzeżenia. Skille z repozytorium [docker/skills](https://github.com/docker/skills) instalujesz tak:

```bash
# Claude Code (w sesji agenta)
/plugin marketplace add docker/skills
/plugin install docker-skills@docker

# inne agenty – skills CLI (wymaga Node.js)
npx skills add docker/skills
```

Pozostałe agenty (Copilot CLI, Cursor, Codex, Gemini CLI) opisuje [instrukcja instalacji](https://docs.docker.com/ai/skills/install/). Po instalacji otwórz nową sesję i poproś o przegląd Dockerfile, podając, że agent ma wskazać użyty skill. Skill to kod zewnętrzny: przejrzyj go przed użyciem, a wynik pracy agenta weryfikuj tak samo jak bez skilla.
