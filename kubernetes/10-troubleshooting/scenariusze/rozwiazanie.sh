#!/usr/bin/env bash
# ★ Rozwiązania scenariuszy awarii – zajrzyj dopiero po własnej diagnozie
cd "$(dirname "$0")" || exit 1

# 1. Serwis bez Podów: selektor app=frontend nie pasuje do etykiet app=web → pusty EndpointSlice
kubectl -n awarie get endpointslices -l kubernetes.io/service-name=web   # ENDPOINTS: <unset>
kubectl -n awarie patch service web -p '{"spec":{"selector":{"app":"web"}}}'

# 2. ErrImagePull/ImagePullBackOff: tag nginx:1.299 nie istnieje (Events: "not found")
kubectl -n awarie set image deployment/api api=nginx:1.29

# 3. CrashLoopBackOff: proces kończy się kodem 1 – przyczyna w logach poprzedniego uruchomienia
kubectl -n awarie logs deploy/worker --previous   # "Brak zmiennej QUEUE_URL"
kubectl -n awarie set env deployment/worker QUEUE_URL=amqp://kolejka:5672

# 4. OOMKilled (exit code 137): proces przekracza limit pamięci 32Mi
kubectl -n awarie describe pod -l app=raport | grep -A3 'Last State'
kubectl -n awarie set resources deployment/raport --limits=memory=512Mi

# 5. Pending: żaden węzeł nie ma 16 wolnych CPU (Events: "Insufficient cpu")
kubectl -n awarie describe pod -l app=analityka | grep -A2 Events
kubectl describe node | grep -A6 'Allocated resources'
kubectl -n awarie set resources deployment/analityka --requests=cpu=100m

# 6. Pending: PVC wskazuje nieistniejącą StorageClass; storageClassName jest niezmienny – usuń i utwórz ponownie
kubectl -n awarie describe pvc archiwum | tail -3   # storageclass "szybki-ssd" not found
kubectl -n awarie delete pod archiwum
kubectl -n awarie delete pvc archiwum
sed 's/storageClassName: szybki-ssd/storageClassName: standard/' 6-archiwum.yaml | kubectl apply -f -

# Wszystko działa?
kubectl -n awarie get pods,pvc
kubectl -n awarie get endpointslices
# Sprzątanie: kubectl delete namespace awarie
