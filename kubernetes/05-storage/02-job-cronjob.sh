#!/usr/bin/env bash
# ★ Job i CronJob – zadania, które się kończą (dodatek do sekcji 5)
cd "$(dirname "$0")" || exit 1

kubectl apply -f job-cronjob.yaml
kubectl wait --for=condition=Complete job/jednorazowe --timeout=60s
kubectl get jobs,pods                         # Pod Joba: STATUS Completed, nie jest restartowany
kubectl logs job/jednorazowe

# CronJob tworzy nowy Job co minutę; historia: 2 ostatnie udane
sleep 70
kubectl get cronjob,jobs                       # Joby co-minute-<liczba>
kubectl create job --from=cronjob/co-minute recznie   # uruchom CronJob od razu, poza harmonogramem
kubectl wait --for=condition=Complete job/recznie --timeout=60s
kubectl logs job/recznie

kubectl delete -f job-cronjob.yaml   # Joby CronJoba (także recznie) usuwa razem z nim garbage collector
