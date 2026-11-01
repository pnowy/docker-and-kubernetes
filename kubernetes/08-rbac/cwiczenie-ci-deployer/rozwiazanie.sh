#!/usr/bin/env bash
# ★ Ćwiczenie sekcji 8: konto ci-deployer. Wymaga namespace notes z Deploymentem notes-api (sekcje 3–5).
cd "$(dirname "$0")" || exit 1
SA=system:serviceaccount:notes:ci-deployer

kubectl apply -f ci-deployer.yaml

kubectl auth can-i patch deployments --as=$SA -n notes       # yes
kubectl auth can-i create deployments --as=$SA -n notes      # no – tylko aktualizacja istniejących
kubectl auth can-i get secrets --as=$SA -n notes             # no
kubectl auth can-i delete pods --as=$SA -n notes             # no
kubectl auth can-i patch deployments --as=$SA -n default     # no

# Wdrożenie jak w CI: zmiana obrazu i oczekiwanie na rollout jako ci-deployer
kubectl --as=$SA -n notes set image deployment/notes-api api=notes-api:1.0.0
kubectl --as=$SA -n notes rollout status deployment/notes-api
kubectl --as=$SA -n notes get secret notes-db                # Forbidden
kubectl --as=$SA -n notes rollout undo deployment/notes-api  # rollout undo to też patch – dozwolony
