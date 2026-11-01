# Sekcja 1 – Wprowadzenie do kontenerów i Dockera

**Cel:** rozumieć, czym kontener różni się od maszyny wirtualnej, skąd wzięły się kontenery i dlaczego po Dockerze przyszedł Kubernetes.
**Czas:** ok. 35 min · sekcja teoretyczna – bez ćwiczeń na komputerze. Jeśli nie masz jeszcze Dockera, zacznij instalację z [sekcji 2](../02-instalacja/) – sprawdzimy ją zaraz po tej sekcji.

## Najważniejsze w skrócie

| Pojęcie                | W jednym zdaniu                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------- |
| maszyna wirtualna (VM) | hypervisor dzieli sprzęt, każda VM ma własne jądro i system – silna izolacja, GB, minuty |
| hypervisor typu 1      | działa na sprzęcie: VMware ESXi, Hyper-V, KVM, Xen                                       |
| hypervisor typu 2      | działa w systemie hosta: VirtualBox, VMware Fusion/Workstation, Parallels, UTM           |
| kontener               | proces na wspólnym jądrze hosta z własnym widokiem systemu – MB, ułamek sekundy          |
| namespaces             | co proces **widzi**: PID, sieć, pliki, hostname, użytkownicy                             |
| cgroups                | ile proces **może zużyć**: CPU, RAM, liczba procesów                                     |
| obraz OCI              | standardowa paczka aplikacji z zależnościami – działa w Dockerze, Podmanie, Kubernetesie |
| Docker Desktop         | na macOS i Windows uruchamia małą VM z Linuksem, w której działają kontenery             |

## Jak to się zmieniało

| Kiedy | Zmiana                              | Co rozwiązała                        | Nowy problem                             |
| ----- | ----------------------------------- | ------------------------------------ | ---------------------------------------- |
| 1990  | mainframe → **PC / serwery x86**    | tani sprzęt, każdy dział ma serwer   | jedna aplikacja na serwer, 10–15% użycia |
| 2000  | serwer fizyczny → **wirtualizacja** | wiele systemów na jednym sprzęcie    | każda VM to cały system do utrzymania    |
| 2010  | serwerownia → **chmura**            | VM w minutę, płacisz za użycie       | „u mnie działa” – różne środowiska       |
| 2014  | host → **kontenery**                | ten sam obraz dev → test → prod      | setki kontenerów na wielu maszynach      |
| 2015+ | kontenery → **orkiestracja**        | Kubernetes: skalowanie, self-healing | złożoność platformy                      |

## Historia kontenerów

| Rok       | Technologia                      | Co dodała                                               |
| --------- | -------------------------------- | ------------------------------------------------------- |
| 1979      | `chroot` (Unix V7)               | proces widzi inny katalog jako `/`                      |
| 2000      | FreeBSD jails                    | osobne procesy, sieć i użytkownicy                      |
| 2004      | Solaris Zones                    | pełne „kontenery” systemowe                             |
| 2002–2013 | Linux namespaces                 | mnt (2002) … pid, net (2006–08) … user (2013)           |
| 2006–2008 | cgroups (Google)                 | limity CPU / RAM dla grup procesów, jądro 2.6.24        |
| 2008      | LXC                              | namespaces + cgroups razem, ale trudne w użyciu         |
| 2013      | Docker                           | obraz + rejestr + proste CLI = kontener dla programisty |
| 2014      | Kubernetes                       | otwarta wersja wewnętrznego systemu Google (Borg)       |
| 2015      | OCI (Open Container Initiative)  | standard obrazu i runtime'u – `runc`; Kubernetes 1.0    |
| 2017      | containerd w CNCF                | runtime wspólny dla Dockera i Kubernetesa               |
| 2022      | Kubernetes 1.24 bez `dockershim` | kubelet rozmawia z containerd przez CRI                 |

## Pytania kontrolne

1. Ile jąder systemu działa, gdy na jednym serwerze uruchomisz 3 maszyny wirtualne, a ile przy 3 kontenerach?
2. Dlaczego obraz zbudowany dla Linuksa nie uruchomi się „natywnie” na macOS i co z tym robi Docker Desktop?
3. Co Docker dodał do mechanizmów, które jądro Linuksa miało już przed 2013 rokiem?
4. Czy obraz zbudowany Dockerem zadziała w Kubernetesie, który nie używa Docker Engine? Dlaczego?

<details>
<summary><strong>Odpowiedzi</strong></summary>

1. Przy 3 VM – 4 jądra (host + jedno w każdej VM), przy 3 kontenerach – 1 jądro (wspólne).
2. Kontener korzysta z jądra hosta, a macOS nie ma jądra Linuksa. Docker Desktop uruchamia małą VM z Linuksem i tam działają kontenery.
3. Obraz (paczkę aplikacji z zależnościami), rejestr do dzielenia się obrazami i proste CLI.
4. Tak – obraz jest w standardzie OCI, a Kubernetes uruchamia go przez containerd lub CRI-O.

</details>

## Do poczytania

- Pierwsza prezentacja Dockera (PyCon 2013): <https://www.youtube.com/watch?v=wW9CAH9nSLs>
- Kontener a VM: <https://www.docker.com/resources/what-container/>
- Docker Desktop – maszyna wirtualna: <https://docs.docker.com/desktop/features/vmm/>
- Koniec `dockershim` w Kubernetesie: <https://kubernetes.io/blog/2022/02/17/dockershim-faq/>
