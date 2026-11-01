# syntax=docker/dockerfile:1

# ── Etap 1: zależności produkcyjne ───────────────────────────
FROM node:24-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

# ── Etap 2: kompilacja TypeScript ────────────────────────────
FROM node:24-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci
COPY tsconfig.json ./
COPY src/ src/
RUN npm run build

# ── Etap dev: "docker compose watch" (sync+restart restartuje kontener po zmianie) ──
FROM build AS dev
ENV NODE_ENV=development
CMD ["node", "src/server.ts"]

# ── Etap 3: obraz produkcyjny ────────────────────────────────
FROM node:24-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
# STORAGE=postgres (domyślnie) albo json: docker build --build-arg STORAGE=json – ENV zapisuje wartość w obrazie
ARG STORAGE=postgres
ENV STORAGE=${STORAGE} DATA_FILE=/app/data/notes.json
RUN mkdir data && chown node:node data
# obraz node ma gotowego użytkownika "node" (UID 1000) – nie uruchamiamy jako root
USER node
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD ["node", "-e", "fetch('http://localhost:3000/healthz').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]
CMD ["node", "dist/server.js"]
