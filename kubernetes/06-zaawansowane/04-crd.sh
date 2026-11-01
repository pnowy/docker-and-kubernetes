#!/usr/bin/env bash
# 6.3 Ćwiczenie: tworzenie własnych zasobów (CRD)
cd "$(dirname "$0")" || exit 1

# 32. Zdefiniuj własny typ zasobu: crd-mojaaplikacja.yaml
# 33. Zastosuj CRD
kubectl apply -f crd-mojaaplikacja.yaml
kubectl get crd
kubectl wait --for=condition=established crd/mojeaplikacje.example.com

# 34. Utwórz instancję własnego zasobu
kubectl apply -f moja-instancja.yaml
kubectl get mojeaplikacje
kubectl get ma

# 35. Obejrzyj zasób w formacie YAML
kubectl get mojaaplikacja pierwsza-aplikacja -o yaml
kubectl explain mojaaplikacja.spec          # schemat z CRD działa jak dokumentacja wbudowanych typów

# Walidacja schematu: replicas < 1 zostanie odrzucone przez API Server
kubectl patch ma pierwsza-aplikacja --type=merge -p '{"spec":{"replicas":0}}' || true

# CRD to tylko nowy typ danych w API – bez kontrolera (operatora) nic nie tworzy Podów
kubectl get pods                             # brak Podów pierwsza-aplikacja

# Sprzątanie: usunięcie CRD usuwa też wszystkie jego obiekty
kubectl delete -f crd-mojaaplikacja.yaml
