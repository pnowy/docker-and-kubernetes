# Sekcja 2 – Instalacja Dockera na Ubuntu

**Cel:** każdy ma działającego Dockera z Compose i Buildx (2A) i widzi na własne oczy, że kontener to zwykły proces z własnym widokiem systemu i limitami (2B).
**Czas:** ok. 10 min + 10 min (instalacja w VM – do 20 min).

## Pliki w katalogu

| Plik                                                                         | Do czego                                                                       |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| [install-docker-ubuntu.sh](install-docker-ubuntu.sh)                         | Docker Engine na Ubuntu 24.04 z repozytorium apt                               |
| [install-docker-convenience-script.sh](install-docker-convenience-script.sh) | instalacja skryptem get.docker.com (tylko VM do testów)                        |
| [sprawdz-srodowisko.sh](sprawdz-srodowisko.sh)                               | polecenia ćwiczenia 2A                                                         |
| [kontener-to-proces.sh](kontener-to-proces.sh)                               | polecenia ćwiczenia 2B (demo prowadzącego)                                     |
| [multipass-mac-fix.yaml](multipass-mac-fix.yaml)                             | poprawka DNS dla VM Multipass na macOS (`--cloud-init`)                        |
| [powloka.sh](powloka.sh)                                                     | dla chętnych: autouzupełnianie, zsh + oh-my-zsh, starship z kontekstem Dockera |

## Gdzie działa Docker?

| System  | Co instalujesz      | Gdzie są kontenery                                               |
| ------- | ------------------- | ---------------------------------------------------------------- |
| Linux   | Docker Engine (apt) | bezpośrednio na hoście – `ps` hosta widzi ich procesy            |
| macOS   | Docker Desktop      | w VM z Linuksem (Docker VMM albo Apple Virtualization framework) |
| Windows | Docker Desktop      | w VM WSL 2 (albo Hyper-V)                                        |

Na macOS i Windows na hoście działa tylko klient `docker`. Daemon `dockerd`, containerd i same kontenery są w maszynie wirtualnej.

## Którą ścieżkę wybrać?

| Masz                                     | Zrób                                                                                                             |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Docker Desktop (macOS / Windows / Linux) | od razu [ćwiczenie 2A](#ćwiczenie-2a--sprawdzenie-środowiska)                                                    |
| maszynę wirtualną z Ubuntu 24.04         | [install-docker-ubuntu.sh](install-docker-ubuntu.sh) (repozytorium apt), potem ćwiczenie 2A                      |
| VM tylko do testów                       | [install-docker-convenience-script.sh](install-docker-convenience-script.sh) (get.docker.com – nie na produkcję) |

**Uwaga do materiałów ALX:** kroki instalacji z wydruku działają na komputerach x86_64. Na procesorach ARM (np. VM na Macu z Apple Silicon) krok 3 z `arch=amd64` doda niewłaściwe repozytorium – użyj [install-docker-ubuntu.sh](install-docker-ubuntu.sh), który wykrywa architekturę i odpowiada aktualnej [instrukcji Dockera](https://docs.docker.com/engine/install/ubuntu/) (dodatkowo instaluje pluginy `docker-buildx-plugin` i `docker-compose-plugin`, potrzebne w sekcjach 8 i 13).

Na Ubuntu po `usermod -aG docker $USER` wyloguj się i zaloguj ponownie (albo `newgrp docker`). Członkostwo w grupie `docker` daje uprawnienia równoważne `root`.

## Ćwiczenie 2A – sprawdzenie środowiska

Wykonaj polecenia pojedynczo (pełna lista: [sprawdz-srodowisko.sh](sprawdz-srodowisko.sh)).

| Polecenie                     | Oczekiwany wynik                                               |
| ----------------------------- | -------------------------------------------------------------- |
| `docker version`              | dwie sekcje: **Client** i **Server** (np. 29.x)                |
| `docker info`                 | system, architektura (`x86_64` / `aarch64`), liczba kontenerów |
| `docker compose version`      | `Docker Compose version v2…` lub nowszy                        |
| `docker buildx version`       | `github.com/docker/buildx v0…`                                 |
| `docker context ls`           | kontekst z gwiazdką `*` – z tym daemonem rozmawia CLI          |
| `docker run --rm hello-world` | `Hello from Docker!`                                           |

**Pytanie:** przeczytaj komunikat `hello-world` – jakie 4 kroki wykonał Docker?

### Gdy coś nie działa

| Objaw                                      | Przyczyna i rozwiązanie                                                    |
| ------------------------------------------ | -------------------------------------------------------------------------- |
| `Cannot connect to the Docker daemon`      | daemon nie działa – uruchom Docker Desktop / `sudo systemctl start docker` |
| `permission denied … /var/run/docker.sock` | brak grupy `docker` – `newgrp docker` albo ponowne logowanie               |
| `docker version` pokazuje tylko Client     | zły kontekst – `docker context use default` (lub `desktop-linux`)          |
| `toomanyrequests` przy pull                | limit Docker Hub dla anonimowych – `docker login`                          |
| `docker-compose: command not found`        | stara składnia – używamy `docker compose` (ze spacją)                      |

<details>
<summary><strong>Odpowiedź</strong></summary>

1. Klient (CLI) połączył się z daemonem `dockerd`.
2. Daemon nie miał obrazu `hello-world` lokalnie, więc pobrał go z Docker Hub.
3. Daemon utworzył z obrazu nowy kontener i uruchomił w nim program.
4. Daemon przesłał wynik programu do klienta, który wyświetlił go w terminalu.

To dokładnie ścieżka z animacji „Co się dzieje przy `docker run`” z sekcji 1.

</details>

## Dla chętnych – wygodny terminal na Linuksie

Na VM z Ubuntu (i na jump-boksie w części Kubernetes) warto od razu włączyć autouzupełnianie i czytelny prompt. Polecenia: [powloka.sh](powloka.sh), wykonuj pojedynczo.

| Krok            | Co daje                                                                                                                      |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| bash-completion | `docker con<TAB><TAB>` podpowiada podpolecenia, nazwy kontenerów i obrazów – pakiet `docker-ce-cli` ma gotowe pliki          |
| zsh + oh-my-zsh | wygodniejsza powłoka; wtyczka `docker` – uzupełnianie `docker` i `docker compose` oraz aliasy                                |
| starship        | prompt pokazuje katalog, gałąź git i **kontekst Dockera** (`via 🐳 zdalny`), gdy CLI rozmawia z innym daemonem niż `default` |

Moduł `docker_context` w starship domyślnie działa tylko w katalogach z `compose.yaml` albo `Dockerfile` – w `~/.config/starship.toml` ustawiamy `only_with_files = false`. Zmiana powłoki (`chsh`) działa od następnego logowania; od razu: `exec zsh`.

**Oczekiwany wynik:** po `docker context use zdalny` prompt pokazuje `via 🐳 zdalny`, po `docker context use default` – znika.

macOS: oh-my-zsh tym samym poleceniem, starship przez `brew install starship`; zsh jest domyślną powłoką.

## Ćwiczenie 2B – kontener to tylko proces

Każde polecenie wpisuj w terminalu i porównuj wynik z kolumną „Oczekiwany wynik”. Wszystkie polecenia: [kontener-to-proces.sh](kontener-to-proces.sh).

### Krok 1 – jeden kontener, dwa punkty widzenia

Uruchom w tle kontener, który tylko „śpi”:

```bash
docker run -d --name proces busybox:1.37 sleep 600
```

| Zadanie                       | Polecenie                     | Oczekiwany wynik                                |
| ----------------------------- | ----------------------------- | ----------------------------------------------- |
| Jak proces widzi **host**?    | `docker top proces`           | `sleep 600` z dużym numerem PID (np. 14581)     |
| Jak proces widzi **siebie**?  | `docker exec proces ps`       | `sleep 600` ma **PID 1**, widać tylko 2 procesy |
| Jaką nazwę hosta ma kontener? | `docker exec proces hostname` | skrót ID kontenera (np. `c59e674e0ff5`)         |

**Pytanie:** dlaczego ten sam proces ma dwa różne numery PID?

### Krok 2 – znajdź proces „na hoście”

**Linux (Docker Engine):** proces kontenera to zwykły proces hosta.

```bash
ps -ef | grep "[s]leep 600"
```

Oczekiwany wynik: `sleep 600` z tym samym PID co w `docker top`.

**macOS / Windows (Docker Desktop):** `ps` w terminalu Maca niczego nie znajdzie – proces działa w maszynie wirtualnej. Zajrzyj do niej pomocniczym kontenerem, który dzieli z VM przestrzeń nazw PID (`--pid=host`):

```bash
docker run --rm --pid=host busybox:1.37 ps -o pid,ppid,comm | grep -E "PID|sleep|shim"
docker run --rm --pid=host busybox:1.37 sh -c 'grep NSpid /proc/$(pidof sleep)/status'
```

Oczekiwany wynik: `sleep` z tym samym PID co w `docker top`, jego rodzic to `containerd-shim`, a `NSpid:` pokazuje dwie liczby, np. `14581  1` – numer w VM i numer w kontenerze.

### Krok 3 – wspólne jądro

```bash
docker run --rm busybox:1.37 uname -r
uname -r
```

- **Linux:** oba polecenia pokażą **tę samą** wersję jądra.
- **macOS / Windows:** kontener pokaże jądro `…-linuxkit` albo `…-microsoft-standard-WSL2`, a host coś innego. **Pytanie:** co to mówi o Docker Desktop?

### Krok 4 – limity to cgroups

```bash
docker run -d --name limit --memory 64m --cpus 0.5 busybox:1.37 sleep 600
docker exec limit cat /sys/fs/cgroup/memory.max /sys/fs/cgroup/cpu.max
```

Oczekiwany wynik: `67108864` (64 MiB w bajtach) oraz `50000 100000` (50 ms CPU na każde 100 ms, czyli pół rdzenia).

### Krok 5 – start w ułamku sekundy

```bash
time docker run --rm busybox:1.37 true
```

Oczekiwany wynik: poniżej 1 s (obraz jest już lokalnie). Porównaj ze startem maszyny wirtualnej.

### Dla chętnych (macOS / Windows) – wejdź do VM Docker Desktop

```bash
docker run --rm -it --privileged --pid=host busybox:1.37 nsenter -t 1 -m -u -n -i sh
hostname        # docker-desktop
uname -r        # …-linuxkit
exit
```

`nsenter` przełącza powłokę do przestrzeni nazw procesu nr 1 maszyny wirtualnej – jesteś „na hoście” kontenerów.

### Sprzątanie

```bash
docker rm -f proces limit
```

<details>
<summary><strong>Odpowiedzi</strong></summary>

- **Dwa PID-y:** kontener ma własną przestrzeń nazw PID. Wewnątrz `sleep` jest pierwszym procesem (PID 1), host widzi go jako zwykły proces o swoim numerze. To ten sam proces, nie kopia – `NSpid` pokazuje oba numery naraz.
- **Rodzic `containerd-shim`:** `runc` utworzył proces i zakończył działanie, opiekę przejął shim (animacja z sekcji 1). Dlatego restart `dockerd` nie zabija kontenerów.
- **Nazwa hosta:** osobna przestrzeń nazw UTS. Docker domyślnie ustawia hostname na skrót ID kontenera.
- **Jądro:** kontenery nie mają własnego jądra. Na Linuksie używają jądra hosta, a Docker Desktop uruchamia małą maszynę wirtualną z Linuksem i kontenery dzielą jej jądro. Dlatego obraz dla Linuksa nie zadziała „natywnie” na macOS.
- **Limity:** `--memory` i `--cpus` to wpisy w cgroups – jądro pilnuje ich tak samo jak dla każdego innego procesu.

</details>
