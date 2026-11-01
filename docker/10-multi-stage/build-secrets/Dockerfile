# syntax=docker/dockerfile:1
FROM ubuntu:24.04

# ŹLE: wartość ARG zostaje zapisana w historii obrazu (docker history) – każdy, kto ma obraz, ją odczyta
ARG API_TOKEN
RUN echo "Pobieram zależności z tokenem ARG o długości ${#API_TOKEN}" > /dev/null

# DOBRZE: sekret montowany tylko na czas tej instrukcji RUN – nie trafia do żadnej warstwy ani historii
RUN --mount=type=secret,id=api_token,env=API_TOKEN_SECRET \
    test -n "$API_TOKEN_SECRET" && echo "Sekret dostępny podczas budowania (długość ${#API_TOKEN_SECRET})"
