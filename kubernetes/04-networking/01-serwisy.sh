#!/usr/bin/env bash
# 4.2 Service – typy Serwisów, namespace i DNS na nginx-deployment z sekcji 3 (../03-podstawowe-operacje/deployment.yaml)
cd "$(dirname "$0")" || exit 1
kubectl apply -f ../03-podstawowe-operacje/deployment.yaml

# --- ClusterIP (domyślny): stały adres wewnątrz klastra ---
kubectl apply -f service.yaml
kubectl get service nginx-service              # CLUSTER-IP – wirtualny adres, nie należy do żadnego Poda
kubectl get endpointslices -l kubernetes.io/service-name=nginx-service   # adresy IP Podów za Serwisem
kubectl run toolbox --image=pnowy/toolbox:main -- sleep 3600
kubectl run test --image=busybox:1.37 --rm -i --restart=Never -- \
  sh -c 'wget -qO- http://nginx-service | grep title; nslookup nginx-service.default.svc.cluster.local'

# --- Namespace i pełna nazwa DNS: <serwis>.<namespace>.svc.cluster.local ---
kubectl apply -f namespace.yaml
kubectl apply -n staging -f ../03-podstawowe-operacje/deployment.yaml -f service.yaml   # te same manifesty, inny namespace
kubectl get services -A --field-selector metadata.name=nginx-service                   # dwa nginx-service, różne ClusterIP
kubectl run test --image=busybox:1.37 --rm -i --restart=Never -- sh -c \
  'grep search /etc/resolv.conf; wget -O /dev/null http://nginx-service 2>&1 | grep Connecting; wget -O /dev/null http://nginx-service.staging 2>&1 | grep Connecting'
# Ta sama krótka nazwa z Poda w staging trafia do Serwisu w staging – search zaczyna się od własnego namespace
kubectl run test -n staging --image=busybox:1.37 --rm -i --restart=Never -- sh -c \
  'wget -O /dev/null http://nginx-service 2>&1 | grep Connecting'
# Klient (toolbox w default) woła Serwis products z namespace staging: krótka nazwa nie działa, z namespace – tak
kubectl apply -f products.yaml                  # Deployment httpbin (2 repliki) + Service products w staging
kubectl exec toolbox -- curl -sS -m 5 http://products/get                    # Could not resolve host – szuka products w default
kubectl exec toolbox -- curl -s http://products.staging/get                  # JSON z httpbin, nagłówek Host: products.staging
kubectl exec toolbox -- dig +short products.staging.svc.cluster.local        # ClusterIP Serwisu products
kubectl exec toolbox -- sh -c 'for i in 1 2 3 4; do curl -s http://products.staging/hostname; done'   # odpowiadają różne Pody
kubectl delete namespace staging                # usuwa namespace razem z Deploymentami i Serwisami

# Pody przychodzą i odchodzą, Serwis zostaje: skalowanie zmienia listę adresów w EndpointSlice
kubectl scale deployment nginx-deployment --replicas=5
kubectl get endpointslices -l kubernetes.io/service-name=nginx-service
kubectl scale deployment nginx-deployment --replicas=3

# --- NodePort: port 30000–32767 na każdym węźle ---
kubectl expose deployment nginx-deployment --name=nginx-nodeport --type=NodePort --port=80
NODE_PORT=$(kubectl get service nginx-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
curl -sI "http://$(minikube ip):${NODE_PORT}" | head -2   # jump-box (Linux); macOS/Windows: minikube service nginx-nodeport --url

# --- LoadBalancer: w chmurze zewnętrzny LB; w minikube adres nadaje minikube tunnel ---
kubectl expose deployment nginx-deployment --name=nginx-lb --type=LoadBalancer --port=80
kubectl get service nginx-lb                   # EXTERNAL-IP: <pending> – nikt nie tworzy load balancera
# W drugim terminalu: minikube tunnel   (działa do Ctrl+C, może pytać o hasło sudo)
kubectl get service nginx-lb                   # teraz EXTERNAL-IP ma adres; curl http://<EXTERNAL-IP>

# --- ExternalName: alias DNS na nazwę spoza klastra ---
kubectl create service externalname zewnetrzny --external-name=example.com
kubectl run test --image=busybox:1.37 --rm -i --restart=Never -- nslookup zewnetrzny   # CNAME na example.com

# Sprzątanie (nginx-deployment zostaje)
kubectl delete service nginx-service nginx-nodeport nginx-lb zewnetrzny
