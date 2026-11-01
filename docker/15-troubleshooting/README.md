# Sekcja 15 – Troubleshooting – typowe problemy

**Cel:** szybko diagnozować typowe problemy: kontener się zatrzymuje, port zajęty, brak miejsca, problemy z siecią i uprawnieniami.
**Wymaga:** obrazu `notes-api:1.0.0` z sekcji 10 – `docker build -t notes-api:1.0.0 .` w katalogu [app-node/](../../app-node/).

## Pliki w katalogu

| Plik                                     | Do czego                                         |
| ---------------------------------------- | ------------------------------------------------ |
| [troubleshooting.sh](troubleshooting.sh) | odtworzenie typowych problemów i ich rozwiązania |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Ćwiczenie – zdiagnozuj problem

Wykonuj kolejne sekcje [troubleshooting.sh](troubleshooting.sh): najpierw odtwórz problem, **zanim** przeczytasz rozwiązanie, spróbuj samodzielnie ustalić przyczynę.

Kolejność diagnozy: `docker logs` → `docker inspect` (stan, kod wyjścia) → `docker exec` / `--entrypoint sh` → `docker events`, `docker system df`.
