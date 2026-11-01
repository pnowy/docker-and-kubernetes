#!/usr/bin/env bash
# Sekcja 11 – Bezpieczeństwo kontenerów
cd "$(dirname "$0")" || exit 1

# --- Użytkownik bez uprawnień root ---
docker build -t moj-obraz:1.0 .
docker run --rm moj-obraz:1.0 id                              # uid=999(appuser) – nie root
docker run --rm ubuntu:24.04 id                               # domyślnie root!
docker run --rm --user 1000:1000 ubuntu:24.04 id              # użytkownika można wymusić przy uruchomieniu

# --- Hardening w czasie działania (na obrazie aplikacji notes-api – zbuduj ../../app-node) ---
docker run -d --name utwardzony \
  --read-only --tmpfs /tmp \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --pids-limit 100 --memory 256m \
  -p 8000:3000 notes-api:1.0.0
sleep 2
curl -s http://localhost:8000/healthz; echo                   # aplikacja działa mimo ograniczeń
docker exec utwardzony sh -c 'touch /app/x' || echo "Zapis zablokowany – read-only"
docker exec utwardzony sh -c 'grep Cap /proc/1/status'        # CapEff: 0000000000000000 – brak capabilities
docker rm -f utwardzony

# --- Capabilities: odbierz wszystkie, dodaj tylko potrzebne ---
docker run --rm --cap-drop ALL ubuntu:24.04 chown nobody /tmp || echo "chown wymaga CAP_CHOWN"
docker run --rm --cap-drop ALL --cap-add CHOWN ubuntu:24.04 chown nobody /tmp && echo "chown działa z CAP_CHOWN"

# --- Skanowanie podatności (CVE) ---
docker scout quickview notes-api:1.0.0                      # podsumowanie (Docker Desktop / docker login)
docker scout cves --only-severity critical,high notes-api:1.0.0
docker scout recommendations notes-api:1.0.0                # podpowiedzi lepszego obrazu bazowego
# trivy image notes-api:1.0.0                               # open-source (brew install trivy)
# grype notes-api:1.0.0                                     # Anchore Grype (brew install grype)

# --- SBOM – lista komponentów obrazu ---
docker scout sbom --format list notes-api:1.0.0 | head -20
# docker buildx build --sbom=true --provenance=mode=max -t <rejestr>/notes-api:1.0.0 --push ../../app-node

# --- Pinowanie obrazu bazowego po digeście ---
docker buildx imagetools inspect node:24-slim --format '{{.Manifest.Digest}}'   # użyj w FROM node:24-slim@sha256:...
