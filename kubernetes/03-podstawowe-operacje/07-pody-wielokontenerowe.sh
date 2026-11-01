#!/usr/bin/env bash
# ★ Pody z wieloma kontenerami, init container, sidecar i command/args – dodatek do sekcji 3
cd "$(dirname "$0")" || exit 1

kubectl apply -f pody-wielokontenerowe.yaml
kubectl get pods -l app=pody-demo       # wiele-kontenerow 2/2, sidecar 2/2, init Init:0/2, command-args Completed

# --- 1. Dwa kontenery w Podzie: wspólny localhost i wspólny wolumin ---
kubectl exec pod-wiele-kontenerow -c generator -- wget -qO- localhost   # busybox woła nginx po localhost
kubectl logs pod-wiele-kontenerow -c nginx                              # przy wielu kontenerach -c wybiera kontener
kubectl get pod pod-wiele-kontenerow -o jsonpath='{.spec.containers[*].name}'; echo

# --- 2. Init containers: po kolei, każdy do końca, dopiero potem aplikacja ---
kubectl logs pod-init -c czekaj-na-baze | tail -2                       # czekam na Serwis baza
kubectl create service clusterip baza --tcp=5432
kubectl get pod pod-init -w                                             # Init:0/2 → Init:1/2 → PodInitializing → Running (Ctrl+C)
kubectl logs pod-init                                                   # DB_HOST=baza – plik przygotował drugi init container

# --- 3. Sidecar: init container z restartPolicy: Always działa obok aplikacji ---
kubectl exec pod-sidecar -c nginx -- curl -s -o /dev/null localhost
kubectl logs pod-sidecar -c logi-sidecar                                # linia access.log z nginx przez sidecar
kubectl get pod pod-sidecar -o jsonpath='{.status.initContainerStatuses[0].state}'; echo   # {"running":…} – init container, który nie kończy pracy

# --- 4. command i args ---
kubectl logs pod-command-args                                           # Witaj, Kubernetes! Pod: pod-command-args $(NIEZNANA)
kubectl run jednorazowy --image=busybox:1.37 --restart=Never --command -- sh -c 'echo $((6*7))'   # --command: reszta to command, bez niej – args
kubectl logs jednorazowy

kubectl delete -f pody-wielokontenerowe.yaml
kubectl delete service baza
kubectl delete pod jednorazowy
