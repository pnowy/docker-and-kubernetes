# Sekcja 11 – obraz uruchamiany jako nieuprzywilejowany użytkownik
FROM python:3.13-slim

# W Dockerfile – stwórz i użyj nieuprzywilejowanego użytkownika
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app
COPY --chown=appuser:appuser index.html .
USER appuser

EXPOSE 8000
CMD ["python", "-m", "http.server", "8000"]
