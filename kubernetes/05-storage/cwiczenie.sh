#!/usr/bin/env bash
# 5.3 Ćwiczenie: zarządzanie danymi w Kubernetes (PostgreSQL 18)
cd "$(dirname "$0")" || exit 1

# Statyczny PV (opcjonalnie – PVC może też zostać obsłużony dynamicznie przez domyślną StorageClass)
kubectl apply -f persistent-volume.yaml   # zostanie Available, bo PVC trafia do domyślnej StorageClass (wiązanie z nim: storageClassName: "")
kubectl get pv

# 27. Sprawdź dostępne StorageClasses
kubectl get storageclass

# 28. Utwórz PVC i zweryfikuj status
kubectl apply -f persistent-volume-claim.yaml
kubectl get pvc
# STATUS: Pending (czeka na Poda) lub Bound (dopasowane do PV)
kubectl apply -f pod-z-pvc.yaml
kubectl wait --for=condition=ready pod/postgres-pvc --timeout=120s && kubectl get pvc,pv

# 29. Wdróż bazę PostgreSQL z trwałym storage
kubectl apply -f postgres-statefulset.yaml
kubectl rollout status statefulset/postgres --timeout=120s
until kubectl exec postgres-0 -- pg_isready -U postgres >/dev/null 2>&1; do sleep 2; done   # Pod Ready ≠ baza gotowa

# 30. Połącz się z bazą i utwórz dane
kubectl exec -i postgres-0 -- psql -U postgres <<'SQL'
CREATE TABLE test (id SERIAL, name TEXT);
INSERT INTO test VALUES (1, 'Dane przetrwają restart');
SQL

# 31. Usuń Poda i sprawdź, że dane przetrwały
kubectl delete pod postgres-0
kubectl wait --for=condition=ready pod/postgres-0 --timeout=120s
until kubectl exec postgres-0 -- pg_isready -U postgres >/dev/null 2>&1; do sleep 2; done   # Pod Ready ≠ baza gotowa
kubectl exec -it postgres-0 -- psql -U postgres -c 'SELECT * FROM test;'

# Sprzątanie: usunięcie StatefulSetu nie usuwa PVC z volumeClaimTemplates – dane czekają na ponowne wdrożenie
kubectl delete -f postgres-statefulset.yaml -f pod-z-pvc.yaml -f persistent-volume-claim.yaml
kubectl get pvc                           # db-data-postgres-0 zostaje
kubectl delete pvc db-data-postgres-0
kubectl delete -f persistent-volume.yaml
