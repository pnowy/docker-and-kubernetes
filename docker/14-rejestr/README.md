# Sekcja 14 – Prywatny rejestr obrazów

**Cel:** uruchomić własny rejestr i publikować w nim obrazy; dodatkowo: wersjonowanie, podpisy i CI.
**Wymaga:** obrazu `moj-apache:1.0` z sekcji 4 ([../04-dockerfile/build.sh](../04-dockerfile/build.sh)); przykłady dodatkowe – `notes-api:1.0.0` z sekcji 10.

## Pliki w katalogu

| Plik                                 | Do czego                                                              |
| ------------------------------------ | --------------------------------------------------------------------- |
| [rejestr.sh](rejestr.sh)             | polecenia z sekcji 14: rejestr `registry:2` na porcie 5000, push/pull |
| [wersjonowanie.sh](wersjonowanie.sh) | dodatkowo: jeden obraz – kilka tagów, etykiety OCI                    |
| [podpisy.sh](podpisy.sh)             | dodatkowo: podpis i weryfikacja obrazu narzędziem cosign              |
| [ci/docker.yml](ci/docker.yml)       | dodatkowo: workflow GitHub Actions: build → skan → push → podpis      |

Skrypty to ściągawka – wykonuj polecenia **pojedynczo**, nie uruchamiaj całego pliku.

**Różnice względem materiałów ALX:** `-v /opt/registry:/var/lib/registry` działa na Linuksie; w Docker Desktop kończy się błędem `mounts denied` (katalog `/opt` nie jest udostępniony maszynie wirtualnej) – używamy woluminu `registry-data`. Port 5000 zajęty (na macOS – AirPlay Receiver)? Użyj `-p 5001:5000` i `localhost:5001`.

## Do samodzielnego sprawdzenia

1. Uruchom lokalny rejestr, wypchnij do niego `moj-apache:1.0`, usuń lokalną kopię i pobierz ją z rejestru ([rejestr.sh](rejestr.sh)).
2. Dla chętnych: zbuduj `notes-api` z kilkoma tagami i etykietami OCI ([wersjonowanie.sh](wersjonowanie.sh)).
3. Dla chętnych: podpisz obraz i zweryfikuj podpis ([podpisy.sh](podpisy.sh), wymaga `cosign`).
