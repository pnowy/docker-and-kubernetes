#!/usr/bin/env bash
# ★ Ćwiczenie sekcji 8: logowanie do klastra kontem ServiceAccount przez osobny plik kubeconfig
cd "$(dirname "$0")" || exit 1
NS=zespol-a
KCFG=$PWD/deweloper.kubeconfig

kubectl apply -f deweloper.yaml

# Adres API Servera i certyfikat CA z bieżącego kontekstu (--flatten wkleja plik CA minikube jako base64)
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt

# Token krótkotrwały (zalecany): podpisany JWT, wygasa sam, nigdzie nie jest zapisany w klastrze
TOKEN=$(kubectl -n $NS create token deweloper --duration=8h)
# Alternatywa – token bez terminu ważności z Secretu deweloper-token:
# TOKEN=$(kubectl -n $NS get secret deweloper-token -o jsonpath='{.data.token}' | base64 -d)

# Co jest w tokenie: sub = system:serviceaccount:zespol-a:deweloper, exp = koniec ważności
cut -d. -f2 <<< "$TOKEN" | jq -R '@base64d | fromjson | {sub, exp: (.exp | todate)}'

# Nowy kubeconfig: klaster + użytkownik (token) + kontekst z domyślnym namespace
kubectl config --kubeconfig="$KCFG" set-cluster kurs --server="$SERVER" --certificate-authority=ca.crt --embed-certs=true
kubectl config --kubeconfig="$KCFG" set-credentials deweloper --token="$TOKEN"
kubectl config --kubeconfig="$KCFG" set-context deweloper@kurs --cluster=kurs --user=deweloper --namespace=$NS
kubectl config --kubeconfig="$KCFG" use-context deweloper@kurs

# Praca jako deweloper – jak osoba, która dostała tylko ten plik
export KUBECONFIG=$KCFG
kubectl auth whoami                              # system:serviceaccount:zespol-a:deweloper
kubectl create deployment web --image=nginx      # działa – edit pozwala tworzyć obiekty
kubectl get pods                                 # działa – domyślny namespace z kontekstu
kubectl get pods -n default                      # Forbidden – RoleBinding tylko w zespol-a
kubectl get nodes                                # Forbidden – węzły to zasób całego klastra
kubectl create rolebinding ja-admin --clusterrole=admin --serviceaccount=$NS:deweloper   # Forbidden – edit nie nadaje uprawnień
unset KUBECONFIG

# kubectl to tylko klient HTTPS – to samo zapytanie curl-em z tokenem w nagłówku
curl -s --cacert ca.crt -H "Authorization: Bearer $TOKEN" "$SERVER/api/v1/namespaces/$NS/pods" | jq -r '.items[].metadata.name'
curl -s --cacert ca.crt -H "Authorization: Bearer $TOKEN" "$SERVER/api/v1/nodes" | jq -r .message   # ... is forbidden

# Unieważnienie: token z create token działa do exp; usunięcie konta unieważnia wszystkie jego tokeny
kubectl -n $NS delete serviceaccount deweloper
sleep 10                                         # API Server pamięta udane logowanie ok. 10 s
KUBECONFIG=$KCFG kubectl get pods                # Unauthorized

# Sprzątanie
kubectl delete namespace $NS
rm -f ca.crt "$KCFG"
