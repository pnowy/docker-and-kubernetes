# Użyj oficjalnego obrazu Ubuntu 20.04 jako bazy
FROM ubuntu:20.04

# Dodaj metadane o autorze
LABEL maintainer="twoj.email@example.com"

# Ustaw zmienne środowiskowe, aby uniknąć interaktywnych pytań
ENV DEBIAN_FRONTEND=noninteractive

# Zaktualizuj listę pakietów i zainstaluj Apache oraz curl
RUN apt-get update && apt-get install -y apache2 curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Skopiuj lokalny plik index.html do katalogu serwera WWW
COPY index.html /var/www/html/

# Ustaw katalog roboczy
WORKDIR /var/www/html

# Poinformuj, że kontener nasłuchuje na porcie 80
EXPOSE 80

# Skonfiguruj sprawdzanie stanu zdrowia
HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Domyślne polecenie uruchamiające Apache w trybie foreground
CMD ["apache2ctl", "-D", "FOREGROUND"]
