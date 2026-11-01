#!/usr/bin/env bash
# ★ Sondy startup, readiness i liveness – dodatek do sekcji 3
cd "$(dirname "$0")" || exit 1

kubectl apply -f sondy.yaml
kubectl get pods -l app=sondy -w        # sonda-readiness: 0/1 Running; sonda-liveness: RESTARTS rośnie co ok. 20 s (Ctrl+C)

# Readiness: Pod działa, ale nie dostaje ruchu, dopóki sonda nie przejdzie
kubectl describe pod sonda-readiness | grep Unhealthy   # Readiness probe failed: cat: /tmp/gotowe: No such file
kubectl exec sonda-readiness -- touch /tmp/gotowe
kubectl get pod sonda-readiness         # po kilku sekundach 1/1

# Liveness: kubelet zabija i uruchamia kontener od nowa
kubectl describe pod sonda-liveness | grep -E 'Liveness|Unhealthy|Killing' | tail -4
kubectl get pod sonda-liveness          # po kilku restartach status CrashLoopBackOff

# Startup: nginx startuje 20 s – startupProbe daje mu do 60 s, liveness i readiness czekają
kubectl get pod sonda-startup -w        # ok. 25 s 0/1, potem 1/1 i RESTARTS 0 (Ctrl+C)
kubectl describe pod sonda-startup | grep -E 'Startup|Unhealthy'   # Startup probe failed: connection refused (x4)
# Eksperyment: usuń startupProbe z sondy.yaml i zastosuj ponownie (kubectl delete pod sonda-startup; kubectl apply -f sondy.yaml)
# → liveness (3 × 5 s) zabija kontener przed końcem startu, RESTARTS rośnie bez końca

kubectl delete -f sondy.yaml
