#!/usr/bin/env bash
# Sekcja 10 – Te same zasady w innych językach: Python (Flask + gunicorn) i Java (Spring Boot)
# Zasady jak w notes-api: multi-stage, przypięte wersje, cache zależności, użytkownik bez roota
cd "$(dirname "$0")" || exit 1

# --- Python: virtualenv budowany w etapie build, do obrazu trafia sam .venv i kod ---
docker build -t python-demo:1.0 python
docker run -d --rm --name python-demo -p 8091:8000 python-demo:1.0
sleep 2; curl -s localhost:8091/; echo
docker exec python-demo id                                   # uid=10001(app)
docker stop python-demo

# --- Java: Maven + JDK tylko w etapie build, w obrazie JRE i jar rozbity na warstwy ---
docker build -t java-demo:1.0 java                            # pierwszy build pobiera zależności Mavena (~1–2 min)
docker run -d --rm --name java-demo -m 512m -p 8092:8080 java-demo:1.0
sleep 8; curl -s localhost:8092/; echo
curl -s localhost:8092/actuator/health; echo                 # liveness/readiness dla sond Kubernetesa
docker logs java-demo | grep 'JAVA_TOOL_OPTIONS'             # sterta = 75% limitu pamięci kontenera
docker stop java-demo

# Warstwy: zależności (~22 MB) osobno, kod aplikacji (kilka kB) w ostatniej warstwie
docker history java-demo:1.0 --format '{{.Size}}\t{{.CreatedBy}}' | grep extracted
docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E '^(python-demo|java-demo):'
# Dla porównania obraz buildera maven:3.9-eclipse-temurin-25 waży ~520 MB, a obraz końcowy ~380 MB

# Sprzątanie: docker rmi python-demo:1.0 java-demo:1.0
