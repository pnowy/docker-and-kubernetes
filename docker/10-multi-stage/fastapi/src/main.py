import os

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def root():
    return {"message": "Hello ALX", "version": os.getenv("APP_VERSION", "dev")}
