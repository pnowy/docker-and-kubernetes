# Sekcja 11 – Bezpieczeństwo kontenerów

**Cel:** uruchamiać kontenery z minimalnymi uprawnieniami i sprawdzać obrazy pod kątem podatności.
**Wymaga:** obrazu `notes-api:1.0.0` z sekcji 10 – `docker build -t notes-api:1.0.0 .` w katalogu [app-node/](../../app-node/).

## Pliki w katalogu

| Plik                                                | Do czego                                                                                 |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| [Dockerfile](Dockerfile) · [index.html](index.html) | obraz uruchamiany jako nieuprzywilejowany użytkownik                                     |
| [bezpieczenstwo.sh](bezpieczenstwo.sh)              | demo: non-root, `--read-only`, `--cap-drop ALL`, `no-new-privileges`, Docker Scout, SBOM |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

## Do samodzielnego sprawdzenia

Uruchom notes-api z [bezpieczenstwo.sh](bezpieczenstwo.sh) z pełnym hardeningiem i sprawdź w kontenerze `grep Cap /proc/1/status` oraz próbę zapisu do `/app`.

**Oczekiwany wynik:** `CapEff: 0000000000000000`, zapis jest zablokowany (`Read-only file system`), a aplikacja nadal odpowiada.
