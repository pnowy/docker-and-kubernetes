# ── Etap 1: builder – instalacja zależności do osobnego katalogu /install ──
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Etap 2: runtime – tylko zależności i kod, bez pip-owego cache i plików instalacyjnych ──
FROM python:3.12-slim
WORKDIR /app
# Python w obrazie żyje w /usr/local: paczki trafiają do site-packages, a uvicorn do /usr/local/bin (już w PATH)
COPY --from=builder /install /usr/local
COPY src/ .
ARG STORAGE=mariadb
ENV STORAGE=${STORAGE} DATA_FILE=/app/data/notes.json PYTHONUNBUFFERED=1
# własny użytkownik bez uprawnień roota (obraz python nie ma gotowego, jak "node" w obrazie Node.js)
RUN useradd --uid 1000 --no-create-home app && mkdir data && chown app:app data
USER app
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/healthz')"]
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
