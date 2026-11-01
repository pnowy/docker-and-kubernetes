#!/usr/bin/env bash
# Sekcja 7 sterowana z jump-boxa: skrypty na VM przez scp, instalacja przez ssh, kubeconfig z powrotem na jump-box.
# Adresy i użytkownik maszyn wirtualnych (dane od prowadzącego). Ten sam przebieg automatycznie:
# ../../srodowisko/tools-setup-automated.sh ssh kubeadm kubeconfig
cd "$(dirname "$0")" || exit 1
CP=10.4.0.50          # control plane
WORKERS="10.4.0.100 10.4.0.200"
U=kurs                # użytkownik z sudo na VM

# 0. Klucz SSH jump-boxa na maszynach (raz) i kopia skryptów
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 <<< n   # pomija, jeśli klucz już jest
for h in $CP $WORKERS; do ssh-copy-id "$U@$h"; done
for h in $CP $WORKERS; do scp common.sh install_master.sh install_worker_nodes.sh deploy_nginx.sh "$U@$h:"; done

# Krok 1: Control Plane (kubeadm init + Calico) – kilka minut
ssh -t "$U@$CP" ./install_master.sh   # -t: sudo może zapytać o hasło

# Krok 2: workery – przygotowanie i dołączenie poleceniem z pliku info_join_worker
JOIN=$(ssh "$U@$CP" cat info_join_worker)
for h in $WORKERS; do ssh -t "$U@$h" ./install_worker_nodes.sh && ssh -t "$U@$h" "sudo $JOIN"; done

# Krok 3: weryfikacja – węzły Ready, gdy Calico wystartuje na każdym z nich
ssh "$U@$CP" kubectl get nodes -o wide
ssh "$U@$CP" kubectl get pods -n calico-system

# kubectl na jump-boksie: drugi kontekst obok minikube
scp "$U@$CP:.kube/config" ~/.kube/kubeadm.conf
KUBECONFIG=~/.kube/config:~/.kube/kubeadm.conf kubectl config view --flatten > /tmp/kubeconfig && mv /tmp/kubeconfig ~/.kube/config
kubectl config rename-context kubernetes-admin@kubernetes kubeadm
kubectl config get-contexts                  # minikube i kubeadm
kubectl --context kubeadm get nodes

# Krok 4: testowa aplikacja (deploy_nginx.sh na Control Plane) i test NodePort z jump-boxa
ssh "$U@$CP" ./deploy_nginx.sh
NODE_PORT=$(kubectl --context kubeadm -n testowa get svc test-nginx -o jsonpath='{.spec.ports[0].nodePort}')
for h in $CP $WORKERS; do curl -sI "http://$h:$NODE_PORT" | head -1; done   # NodePort odpowiada na każdym węźle

# Sprzątanie klastra (na każdym węźle, workery najpierw):
# for h in $WORKERS $CP; do ssh "$U@$h" 'sudo kubeadm reset -f && sudo rm -rf /etc/cni/net.d $HOME/.kube'; done
# kubectl config delete-context kubeadm
