import json
import os
import socket
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel

VERSION = os.getenv("APP_VERSION", "dev")
STORAGE = os.getenv("STORAGE", "mariadb")


class JsonStorage:
    """STORAGE=json – notatki w pliku, aplikacja działa bez bazy (sekcje 4–7, zanim dodamy Compose)."""

    def __init__(self, file: str):
        self.file = Path(file)
        self.notes: list[dict] = []

    def init(self):
        self.file.parent.mkdir(parents=True, exist_ok=True)
        if self.file.exists():
            self.notes = json.loads(self.file.read_text())
        print(f"Notatki w pliku {self.file}", flush=True)

    def ping(self) -> bool:
        return True

    def list(self) -> list[dict]:
        return self.notes

    def add(self, text: str) -> dict:
        note = {"id": (self.notes[-1]["id"] if self.notes else 0) + 1, "text": text,
                "created_at": datetime.now(timezone.utc).isoformat()}
        self.notes.append(note)
        self.file.write_text(json.dumps(self.notes, indent=2, ensure_ascii=False))
        return note


class MariaDBStorage:
    """Parametry połączenia ze zmiennych DB_HOST, DB_PORT, DB_USER, DB_NAME, DB_PASSWORD lub DB_PASSWORD_FILE."""

    def connect(self):
        import pymysql

        # hasło w pliku: Docker/Compose secrets, Kubernetes Secret jako wolumin
        path = os.getenv("DB_PASSWORD_FILE")
        password = Path(path).read_text().strip() if path else os.getenv("DB_PASSWORD", "")
        return pymysql.connect(host=os.getenv("DB_HOST", "localhost"), port=int(os.getenv("DB_PORT", "3306")),
                               user=os.getenv("DB_USER", "notes"), password=password,
                               database=os.getenv("DB_NAME", "notes"), autocommit=True, connect_timeout=3)

    def init(self):
        with self.connect() as conn, conn.cursor() as cur:
            cur.execute("CREATE TABLE IF NOT EXISTS notes (id INT AUTO_INCREMENT PRIMARY KEY, text TEXT NOT NULL,"
                        " created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)")
        print("Połączono z bazą danych", flush=True)

    def ping(self) -> bool:
        try:
            with self.connect() as conn:
                conn.ping()
            return True
        except Exception:
            return False

    def list(self) -> list[dict]:
        with self.connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id, text, created_at FROM notes ORDER BY id")
            return [{"id": i, "text": t, "created_at": c.isoformat()} for i, t, c in cur.fetchall()]

    def add(self, text: str) -> dict:
        with self.connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO notes (text) VALUES (%s) RETURNING id, text, created_at", (text,))
            i, t, c = cur.fetchone()
        return {"id": i, "text": t, "created_at": c.isoformat()}


storage = JsonStorage(os.getenv("DATA_FILE", "data/notes.json")) if STORAGE == "json" else MariaDBStorage()
ready = False


def connect_storage() -> bool:
    global ready
    if not ready:
        try:
            storage.init()
            ready = True
        except Exception as err:
            # aplikacja startuje także bez bazy – kolejne żądanie ponawia próbę, a /readyz zgłasza do tego czasu 503
            print(f"Baza niedostępna: {err}", flush=True)
    return ready


@asynccontextmanager
async def lifespan(_app: FastAPI):
    connect_storage()
    yield


app = FastAPI(title="notes-api (Python)", lifespan=lifespan)


class NoteIn(BaseModel):
    text: str


@app.get("/")
def root():
    return {"app": "notes-api-python", "version": VERSION, "storage": STORAGE, "hostname": socket.gethostname()}


# liveness: proces żyje; readiness: można kierować ruch (magazyn notatek odpowiada)
@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    ok = connect_storage() and storage.ping()
    return JSONResponse({"ready": ok}, status_code=200 if ok else 503)


@app.get("/notes")
def list_notes():
    if not connect_storage():
        raise HTTPException(503, "Baza danych niedostępna")
    return storage.list()


@app.post("/notes", status_code=201)
def add_note(note: NoteIn):
    if not connect_storage():
        raise HTTPException(503, "Baza danych niedostępna")
    if not note.text.strip():
        raise HTTPException(400, 'Wymagane pole "text"')
    return storage.add(note.text)
