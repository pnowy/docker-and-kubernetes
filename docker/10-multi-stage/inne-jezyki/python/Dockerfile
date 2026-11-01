# syntax=docker/dockerfile:1

# ── Etap 1: zależności w virtualenv (kompilatory, cache pip zostają tutaj) ──
FROM python:3.14-slim AS build
WORKDIR /app
RUN python -m venv /venv
ENV PATH=/venv/bin:$PATH
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# ── Etap 2: obraz produkcyjny – sam virtualenv i kod ──
FROM python:3.14-slim AS runtime
# bez buforowania stdout (logi od razu w docker logs), bez plików .pyc
ENV PATH=/venv/bin:$PATH PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY --from=build /venv /venv
COPY app.py ./
RUN useradd --uid 10001 --no-create-home app
USER app
EXPOSE 8000
# serwer WSGI zamiast wbudowanego serwera deweloperskiego Flaska
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]
