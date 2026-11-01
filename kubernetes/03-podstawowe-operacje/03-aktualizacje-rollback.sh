#!/usr/bin/env bash
# 3.3 Aktualizacje i roll-backi. Wymaga nginx-deployment (01-pody-i-deploymenty.sh)
cd "$(dirname "$0")" || exit 1

# Rolling Update (materiały: nginx:1.26 – tu 1.28 → 1.29)
kubectl set image deployment/nginx-deployment nginx=nginx:1.29
kubectl annotate deployment/nginx-deployment kubernetes.io/change-cause="nginx 1.29" --overwrite   # opis nowej rewizji (kolumna CHANGE-CAUSE)
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl get rs                 # stary ReplicaSet zostaje z 0 replik – to do niego wraca rollback

# Rollback
# Materiały pokazują szczegóły rewizji 2 na końcu – po dwóch rollbackach rewizja 2 dostaje nowy numer, więc oglądamy ją przed nimi
kubectl rollout history deployment/nginx-deployment --revision=2
kubectl rollout undo deployment/nginx-deployment                  # wraca do poprzedniej rewizji (nginx:1.28)
kubectl rollout undo deployment/nginx-deployment --to-revision=2  # wraca do wskazanej rewizji (nginx:1.29)
kubectl rollout history deployment/nginx-deployment               # numery rewizji rosną: rollback to nowa rewizja
# Ostrzeżenie o last-applied-configuration: w zespole rollback robi się przez kubectl apply poprzedniej wersji pliku z Gita

# Canary Deployment – dwa Deploymenty z tą samą etykietą app i jeden Serwis
kubectl apply -f canary/
# stable: 9 replik, canary: 1 replika -> 10% ruchu na canary
kubectl scale deployment nginx-canary --replicas=1
kubectl scale deployment nginx-stable --replicas=9
kubectl get pods -l app=nginx-canary-demo -L track
kubectl rollout status deployment/nginx-stable
# 50 zapytań przez Serwis: ok. 45 trafia do nginx/1.28 (stable), ok. 5 do nginx/1.29 (canary)
kubectl run licznik --image=busybox:1.37 --rm -i --restart=Never -- \
  sh -c 'for i in $(seq 50); do wget -S -q -O /dev/null http://nginx-canary-demo 2>&1 | grep Server:; done | sort | uniq -c'
kubectl run toolbox --image=pnowy/toolbox:main -- sleep 3600

# Sprzątanie
kubectl delete -f canary/
