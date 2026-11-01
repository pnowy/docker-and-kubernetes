#!/usr/bin/env bash
# ★ ConfigMap i Secret – dodatek do sekcji 3
cd "$(dirname "$0")" || exit 1

# Imperatywnie
kubectl create configmap demo --from-literal=KOLOR=zielony --from-file=pod.yaml   # klucz = nazwa pliku, wartość = jego treść
kubectl get configmap demo -o yaml
kubectl create secret generic demo --from-literal=HASLO=tajne
kubectl get secret demo -o jsonpath='{.data.HASLO}' | base64 -d; echo   # base64 to kodowanie, nie szyfrowanie
kubectl delete configmap demo; kubectl delete secret demo

# Deklaratywnie: konfiguracja jako zmienne i jako pliki
kubectl apply -f konfiguracja.yaml
kubectl wait --for=condition=Ready pod/konfiguracja-demo
kubectl logs konfiguracja-demo                     # zmienne z ConfigMap i Secret, plik app.properties
kubectl exec konfiguracja-demo -- cat /secret/DB_PASSWORD; echo

# Zmiana ConfigMap: pliki w woluminie aktualizują się same (zwykle w ciągu minuty, kubelet odświeża je okresowo),
# zmienne środowiskowe – dopiero po restarcie Poda
kubectl patch configmap app-config --type=merge -p '{"data":{"LOG_LEVEL":"debug","app.properties":"kolor=czerwony\n"}}'
until kubectl exec konfiguracja-demo -- grep -q czerwony /config/app.properties; do sleep 5; done
kubectl exec konfiguracja-demo -- sh -c 'echo "env: $LOG_LEVEL"; cat /config/app.properties'   # env: info, plik: czerwony

kubectl delete -f konfiguracja.yaml
