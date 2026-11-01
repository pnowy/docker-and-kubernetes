import os
import socket

from flask import Flask

app = Flask(__name__)


@app.get("/")
def index():
    return {"app": "python-demo", "hostname": socket.gethostname(), "env": os.environ.get("APP_ENV", "dev")}


@app.get("/healthz")
def healthz():
    return {"status": "ok"}
