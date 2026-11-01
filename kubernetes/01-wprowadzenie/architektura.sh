#!/usr/bin/env bash
# Sekcja 1 – architektura klastra na żywo. Wymaga klastra minikube z sekcji 2 (minikube start ...).

# --- 1.2 Komponenty klastra ---
kubectl cluster-info                      # adres API Servera – jedynego wejścia do klastra
kubectl get nodes -o wide                 # węzły: rola, wersja kubeleta, runtime kontenerów
kubectl get pods -n kube-system -o wide   # etcd, kube-apiserver, kube-scheduler, kube-controller-manager, kube-proxy, coredns, calico
# Komponenty Control Plane to statyczne Pody – kubelet czyta ich manifesty z dysku węzła:
minikube ssh -- ls /etc/kubernetes/manifests

# --- 1.2 Przepływ tworzenia Poda: kubectl → API Server → etcd → Scheduler → kubelet → containerd ---
kubectl create deployment hello --image=nginx:1.29 --replicas=2
kubectl rollout status deployment/hello
kubectl get events --sort-by=.lastTimestamp --field-selector involvedObject.kind=Pod | tail -10   # Scheduled → Pulling → Pulled → Created → Started
kubectl get pods -o wide                                 # kolumna NODE = decyzja schedulera

# --- 1.1 Samonaprawianie: stan pożądany vs aktualny ---
kubectl delete pod -l app=hello --wait=false
kubectl get pods -l app=hello   # ReplicaSet od razu tworzy nowe Pody (inne nazwy, AGE kilka sekund)

# --- 1.3 Pod, Node, Cluster – co API wie o obiektach ---
kubectl api-resources | head -20          # typy obiektów, skróty (po, deploy, svc) i grupy API
kubectl explain pod.spec.containers       # dokumentacja pól prosto z API Servera
kubectl describe node | sed -n '/Capacity/,/Allocatable/p'

# Sprzątanie
kubectl delete deployment hello
