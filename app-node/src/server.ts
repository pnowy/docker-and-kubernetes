import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { hostname } from "node:os";
import { dirname } from "node:path";
import express, { type NextFunction, type Request, type Response } from "express";
import pg from "pg";

// pg czyta PGHOST, PGPORT, PGUSER, PGDATABASE i PGPASSWORD ze zmiennych środowiskowych.
// Hasło można też podać w pliku (Docker/Compose secrets, Kubernetes Secret jako wolumin).
if (process.env.PGPASSWORD_FILE) {
  process.env.PGPASSWORD = readFileSync(process.env.PGPASSWORD_FILE, "utf8").trim();
}

const port = Number(process.env.PORT ?? 3000);
const version = process.env.APP_VERSION ?? "dev";
const storageType = process.env.STORAGE ?? "postgres";

type Note = { id: number; text: string; created_at: string };

interface Storage {
  init(): Promise<void>;
  ping(): Promise<boolean>;
  list(): Promise<Note[]>;
  add(text: string): Promise<Note>;
  close(): Promise<void>;
}

// STORAGE=json – notatki w pliku, aplikacja działa bez bazy (rozdziały 5–9, zanim dodamy Compose)
function jsonStorage(file: string): Storage {
  let notes: Note[] = [];
  return {
    async init() {
      mkdirSync(dirname(file), { recursive: true });
      if (existsSync(file)) notes = JSON.parse(readFileSync(file, "utf8"));
      console.log(`Notatki w pliku ${file}`);
    },
    ping: async () => true,
    list: async () => notes,
    async add(text) {
      const note = { id: (notes.at(-1)?.id ?? 0) + 1, text, created_at: new Date().toISOString() };
      notes.push(note);
      writeFileSync(file, JSON.stringify(notes, null, 2));
      return note;
    },
    close: async () => {},
  };
}

function postgresStorage(): Storage {
  const pool = new pg.Pool();
  // bez tego zerwane połączenie z bazą kończy cały proces
  pool.on("error", (err) => console.error(`Błąd połączenia z bazą: ${err.message}`));
  return {
    async init() {
      for (;;) {
        try {
          await pool.query(
            "CREATE TABLE IF NOT EXISTS notes (id SERIAL PRIMARY KEY, text TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now())",
          );
          console.log("Połączono z bazą danych");
          return;
        } catch (err) {
          console.error(`Baza niedostępna (${(err as Error).message}), ponawiam za 2 s`);
          await new Promise((resolve) => setTimeout(resolve, 2000));
        }
      }
    },
    ping: () => pool.query("SELECT 1").then(() => true, () => false),
    list: async () => (await pool.query("SELECT id, text, created_at FROM notes ORDER BY id")).rows,
    add: async (text) =>
      (await pool.query("INSERT INTO notes (text) VALUES ($1) RETURNING id, text, created_at", [text])).rows[0],
    close: () => pool.end(),
  };
}

const storage = storageType === "json" ? jsonStorage(process.env.DATA_FILE ?? "data/notes.json") : postgresStorage();
let ready = false;

const app = express();
app.use(express.json());
app.use((req, _res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

app.get("/", (_req, res) => {
  res.json({ app: "notes-api", version, storage: storageType, hostname: hostname() });
});

// liveness: proces żyje; readiness: można kierować ruch (magazyn notatek odpowiada)
app.get("/healthz", (_req, res) => {
  res.json({ status: "ok" });
});

app.get("/readyz", async (_req, res) => {
  const ok = ready && (await storage.ping());
  res.status(ok ? 200 : 503).json({ ready: ok });
});

app.use("/notes", (_req, res, next) => {
  if (!ready) return void res.status(503).json({ error: "Baza danych niedostępna" });
  next();
});

app.get("/notes", async (_req, res) => {
  res.json(await storage.list());
});

app.post("/notes", async (req, res) => {
  const text: unknown = req.body?.text;
  if (typeof text !== "string" || text.trim() === "") {
    return void res.status(400).json({ error: 'Wymagane pole "text"' });
  }
  res.status(201).json(await storage.add(text));
});

app.use((_req, res) => {
  res.status(404).json({ error: "Nie znaleziono" });
});

// Express 5 przekazuje tu także błędy z funkcji async (np. zapytania do bazy)
app.use((err: Error & { status?: number }, _req: Request, res: Response, _next: NextFunction) => {
  console.error(err);
  res.status(err.status ?? 500).json({ error: err.status ? err.message : "Błąd serwera" });
});

const server = app.listen(port, () => console.log(`notes-api ${version} nasłuchuje na porcie ${port}`));
void storage.init().then(() => {
  ready = true;
});

// docker stop wysyła SIGTERM do procesu o PID 1 – kończymy pracę łagodnie zamiast czekać na SIGKILL.
for (const signal of ["SIGTERM", "SIGINT"] as const) {
  process.on(signal, () => {
    console.log(`Otrzymano ${signal}, zamykam serwer`);
    server.close(() => void storage.close().then(() => process.exit(0)));
  });
}
