# ── Etap 1: Builder ─────────────────────────────
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# ── Etap 2: Runtime ─────────────────────────────
FROM python:3.12-slim
WORKDIR /app
# tylko zależności, bez pip (Dockerfile nie obsługuje komentarzy na końcu linii – w materiałach ALX stoją za COPY i USER)
COPY --from=builder /install /usr/local
COPY src/ .
# nie root!
USER nobody
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
