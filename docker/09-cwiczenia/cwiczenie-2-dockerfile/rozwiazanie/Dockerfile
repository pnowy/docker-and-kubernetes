# Ćwiczenie II – Dockerfile z sekcji 4 po modyfikacjach (kroki 10–11)
FROM ubuntu:20.04

# 10. Zmieniony maintainer
LABEL maintainer="twoj.nowy@email.com"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y apache2 curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY index.html /var/www/html/
# 11. Dodany plik alx.html
COPY alx.html /var/www/html/

WORKDIR /var/www/html
EXPOSE 80

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["apache2ctl", "-D", "FOREGROUND"]
