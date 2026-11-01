#!/usr/bin/env bash
# Krok 1: inicjalizacja Control Plane – uruchom na maszynie master
set -euo pipefail
cd "$(dirname "$0")" || exit 1

PAUZA="${PAUZA:-1}"
krok()   { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }
gotowe() { printf '\033[1;32m✓ %s\033[0m\n' "$*"; sleep "$PAUZA"; }

./common.sh

# Pula adresów Podów nie może nachodzić na sieć maszyn wirtualnych. Domyślna pula Calico 192.168.0.0/16
# koliduje z typowymi sieciami VM (192.168.x.0/24), dlatego używamy 10.244.0.0/16 i poprawiamy custom-resources.yaml.
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
krok "Control Plane: kubeadm init (pula adresów Podów ${POD_CIDR}) – 1–3 min"
sudo kubeadm init --pod-network-cidr="${POD_CIDR}"
gotowe "Control Plane działa: API server, etcd, scheduler i controller-manager jako static Pods (/etc/kubernetes/manifests)"

krok "kubeconfig administratora dla użytkownika $(whoami)"
mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
gotowe "~/.kube/config gotowy – kubectl gada z klastrem bez sudo"
kubectl get nodes   # NotReady – brak sieci Podów (CNI), naprawi to Calico poniżej
sleep "$PAUZA"

krok "Polecenie dołączenia workerów (token ważny 24 h)"
sudo kubeadm token create --print-join-command | tee info_join_worker
gotowe "Polecenie kubeadm join zapisano w pliku info_join_worker"

# Krok 3 (poprawka błędu 3): Calico przez operator Tigera zamiast przestarzałego manifestu v3.25.0
# v3_projectcalico_org.yaml dotyczy Kubernetes 1.36+; dla 1.34/1.35 użyj v3_projectcalico_org-v1beta1.yaml
CALICO_VERSION="${CALICO_VERSION:-v3.33.0}"
# VXLAN zawsze: domyślne VXLANCrossSubnet w jednej podsieci wysyła pakiety Podów bez enkapsulacji,
# a chmury (np. Azure) nie trasują adresów Podów między VM – Pody na różnych węzłach się nie widzą
CALICO_ENCAPSULATION="${CALICO_ENCAPSULATION:-VXLAN}"
krok "Sieć Podów: Calico ${CALICO_VERSION} przez operator Tigera (enkapsulacja ${CALICO_ENCAPSULATION})"
kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/v3_projectcalico_org.yaml"
gotowe "CRD Calico zarejestrowane – API zna nowe typy obiektów"
kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
gotowe "Operator Tigera uruchomiony w namespace tigera-operator"
curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml" \
  | sed -e "s#cidr: 192.168.0.0/16#cidr: ${POD_CIDR}#" -e "s#encapsulation: VXLANCrossSubnet#encapsulation: ${CALICO_ENCAPSULATION}#" \
  | kubectl create -f -
gotowe "Obiekt Installation utworzony – operator instaluje teraz Calico na każdym węźle (1–2 min)"

printf '\n\033[1;32mControl Plane gotowy.\033[0m Dalej:\n'
echo "  1. Na każdym workerze: ./install_worker_nodes.sh, potem polecenie z info_join_worker"
echo "  2. Tutaj obserwuj: kubectl get nodes -w   (NotReady → Ready, gdy Calico wstanie)"
