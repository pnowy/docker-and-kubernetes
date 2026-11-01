# syntax=docker/dockerfile:1

# ── Etap 1: build Mavenem (JDK, Maven i repozytorium ~/.m2 zostają tutaj) ──
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /src
COPY pom.xml ./
RUN --mount=type=cache,target=/root/.m2 mvn -q dependency:go-offline
COPY src/ src/
RUN --mount=type=cache,target=/root/.m2 mvn -q package -DskipTests
# rozbicie jara na warstwy: zależności zmieniają się rzadko, kod aplikacji – często
RUN java -Djarmode=tools -jar target/app.jar extract --layers --destination /extracted

# ── Etap 2: sam JRE (bez kompilatora i Mavena) ──
FROM eclipse-temurin:25-jre AS runtime
WORKDIR /app
RUN useradd --uid 10001 --no-create-home app
COPY --from=build /extracted/dependencies/ ./
COPY --from=build /extracted/spring-boot-loader/ ./
COPY --from=build /extracted/snapshot-dependencies/ ./
COPY --from=build /extracted/application/ ./
USER app
EXPOSE 8080
# JVM dopasowuje pamięć sterty do limitu kontenera (docker run -m / limits w Kubernetesie)
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"
CMD ["java", "-jar", "app.jar"]
