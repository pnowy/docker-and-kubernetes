#!/usr/bin/env bash
# ★ Ćwiczenie sekcji 4: notes-api za Serwisem i Ingressem, NetworkPolicy dla namespace notes.
# Wymaga Deploymentu notes-api z ćwiczenia sekcji 3 (../../03-podstawowe-operacje/cwiczenie-notes-api/).
cd "$(dirname "$0")" || exit 1
INGRESS_IP=$(minikube ip)   # macOS/Windows: minikube tunnel w osobnym terminalu i INGRESS_IP=127.0.0.1

# 1. Service i Ingress
kubectl apply -f notes-api-siec.yaml
kubectl -n notes wait ingress/notes-api --for=jsonpath='{.status.loadBalancer.ingress}' --timeout=90s   # kontroler przejął regułę
kubectl -n notes get service,endpointslices,ingress

# 2. Serwis rozkłada ruch: kolejne zapytania trafiają do różnych Podów (pole hostname)
for i in 1 2 3 4 5 6; do curl -s -H "Host: notes.local" "http://${INGRESS_IP}/"; echo; done

# 3. DNS z innego namespace: pełna nazwa <serwis>.<namespace>.svc.cluster.local
kubectl run dns-test --image=busybox:1.37 --rm -i --restart=Never -- wget -qO- -T 5 http://notes-api.notes.svc.cluster.local/

# 4. NetworkPolicy: z innych Podów blokada, przez Ingress nadal działa
kubectl apply -f network-policy.yaml
kubectl run dns-test --image=busybox:1.37 --rm -i --restart=Never -- wget -qO- -T 5 http://notes-api.notes/   # download timed out
curl -s -H "Host: notes.local" "http://${INGRESS_IP}/"; echo                                                 # odpowiada
