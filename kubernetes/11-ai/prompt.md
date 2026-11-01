# Przykład dobrego promptu – manifesty Kubernetes

Krótki prompt („napisz manifesty dla mojego API notatek z Ingressem”) daje odpowiedź jak w [wygenerowany/notes-api.yaml](wygenerowany/notes-api.yaml): stare API, zgadnięte porty i ścieżki, hasło w YAML. Lepszy wynik daje prompt z kontekstem i wymaganiami:

```text
Kontekst:
- Kubernetes 1.37 (minikube), kontroler Ingress NGINX (ingressClassName: nginx).
- Aplikacja notes-api: Node.js, obraz notes-api:1.1.0 załadowany do minikube (nie ma go w rejestrze),
  słucha na porcie 3000, sondy: GET /healthz (liveness), GET /readyz (readiness, 503 gdy baza niedostępna).
- Konfiguracja przez zmienne: STORAGE=postgres, PGHOST, PGDATABASE, PGUSER, PGPASSWORD_FILE (ścieżka do pliku z hasłem).
- Hasło jest w istniejącym Secrecie notes-db (klucz password) – nie twórz go i nie wpisuj hasła.

Zadanie:
Napisz manifesty dla namespace notes: ConfigMap, Deployment (2 repliki, rolling update bez spadku dostępności),
Service ClusterIP (port 80 → 3000) i Ingress dla hosta notes.local.

Wymagania:
- tylko stabilne wersje API dostępne w Kubernetesie 1.37;
- requests i limits CPU/RAM, readinessProbe i livenessProbe;
- Secret montowany jako plik w /run/secrets/db;
- securityContext: runAsNonRoot, bez eskalacji uprawnień;
- komentarz tylko przy nieoczywistych decyzjach.

Na końcu wypisz polecenia, którymi mam zweryfikować manifesty przed wdrożeniem.
```

Wynik i tak sprawdź według [checklista.md](checklista.md) i poleceniami z [ai.sh](ai.sh) – dobry prompt zmniejsza liczbę błędów, ale ich nie eliminuje.
