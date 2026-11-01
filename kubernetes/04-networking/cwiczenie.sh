#!/usr/bin/env bash
# 4.3 Ćwiczenie: konfiguracja sieci w Kubernetes (minikube z --cni=calico i addonem ingress)
cd "$(dirname "$0")" || exit 1

# 22. Wdróż aplikację frontend i backend
kubectl create deployment frontend --image=nginx:1.29 --replicas=2
kubectl create deployment backend  --image=httpd:2.4  --replicas=2

# 23. Utwórz Serwisy
kubectl expose deployment frontend --port=80 --type=ClusterIP --name=frontend-svc
kubectl expose deployment backend  --port=80 --type=ClusterIP --name=backend-svc
kubectl rollout status deployment/frontend && kubectl rollout status deployment/backend

# 24. Sprawdź DNS między Podami (interaktywnie):
#   kubectl run debug --image=busybox:1.37 --rm -it -- sh
#   wget -qO- http://frontend-svc
#   nslookup backend-svc
kubectl run debug --image=busybox:1.37 --rm -i --restart=Never -- sh -c 'wget -qO- http://frontend-svc | grep title; nslookup backend-svc'

# 25. Zastosuj Ingress (kontroler: minikube addons enable ingress)
kubectl apply -f ingress.yaml
kubectl get ingress                     # ADDRESS pojawia się po kilkunastu sekundach
# Jump-box (Linux): kontroler słucha na porcie 80 węzła minikube, adres: minikube ip.
# macOS/Windows: minikube tunnel w osobnym terminalu i 127.0.0.1 zamiast $(minikube ip).
# Zamiast wpisu app.example.com w /etc/hosts podajemy nagłówek Host:
curl -H "Host: app.example.com" "http://$(minikube ip)/"        # strona nginx (frontend)
curl -H "Host: app.example.com" "http://$(minikube ip)/api"     # "It works!" z httpd (backend)

# Opcja: nip.io – prawdziwa nazwa hosta zamiast nagłówka Host, działa też w przeglądarce na pulpicie jump-boksa (RDP).
# Publiczny DNS nip.io zwraca adres zapisany w nazwie: app.192.168.49.2.nip.io → 192.168.49.2 (wymaga internetu)
HOST="app.$(minikube ip).nip.io"                                   # macOS/Windows z minikube tunnel: app.127.0.0.1.nip.io
sed "s/app.example.com/$HOST/" ingress.yaml | kubectl apply -f -   # ten sam Ingress, tylko inny host
kubectl get ingress                                                # HOSTS: app.<IP minikube>.nip.io
curl "http://$HOST/"
curl "http://$HOST/api"
echo "Przeglądarka: http://$HOST/  i  http://$HOST/api"
# Powrót do app.example.com (krok 26 testuje nagłówkiem Host): kubectl apply -f ingress.yaml

# 26. Przetestuj Network Policy – zablokuj dostęp z nieautoryzowanych Podów
kubectl apply -f network-policy.yaml
kubectl run unauthorized --image=busybox:1.37 --rm -i --restart=Never -- wget -qO- -T 5 http://backend-svc
# Powinno zakończyć się timeoutem (download timed out)
kubectl run authorized --labels=app=frontend --image=busybox:1.37 --rm -i --restart=Never -- wget -qO- -T 5 http://backend-svc
# Pod z etykietą app=frontend ma dostęp
curl -H "Host: app.example.com" "http://$(minikube ip)/api"
# Teraz 504 – kontroler Ingress (namespace ingress-nginx) też nie ma etykiety app=frontend, więc polityka go blokuje

# Sprzątanie
kubectl delete -f network-policy.yaml -f ingress.yaml
kubectl delete deployment frontend backend
kubectl delete service frontend-svc backend-svc
