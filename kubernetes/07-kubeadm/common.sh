#!/usr/bin/env bash
# Wspólne kroki dla master i worker: containerd + kubeadm/kubelet/kubectl (Ubuntu 22.04/24.04)
set -euo pipefail

K8S_MINOR="${K8S_MINOR:-v1.37}"
PAUZA="${PAUZA:-1}"   # PAUZA=0 – bez zatrzymań między krokami
krok()   { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }
gotowe() { printf '\033[1;32m✓ %s\033[0m\n' "$*"; sleep "$PAUZA"; }

krok "[$(hostname)] 1/5 Wyłączam swap – kubelet nie wystartuje, gdy swap jest aktywny"
sudo swapoff -a
sudo sed -i '/\sswap\s/ s/^/#/' /etc/fstab
gotowe "Swap wyłączony teraz i po restarcie (wpis w /etc/fstab zakomentowany)"

krok "2/5 Moduły jądra i sysctl wymagane przez sieć Podów"
cat <<CONF | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
CONF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<CONF | sudo tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
CONF
sudo sysctl --system > /dev/null
gotowe "overlay (warstwy obrazów) i br_netfilter (iptables widzi ruch z mostka) załadowane, ip_forward=$(sysctl -n net.ipv4.ip_forward)"

# containerd 2.x z repozytorium Dockera (pakiet containerd.io) – containerd 1.7 z Ubuntu
# jest na granicy wsparcia aktualnego kubeleta. Cgroup driver systemd (zgodny z kubeletem).
krok "3/5 Container runtime: containerd z repozytorium Dockera"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y containerd.io
gotowe "Zainstalowano $(containerd --version | awk '{print $1, $3}')"

krok "4/5 Konfiguracja containerd: cgroup driver systemd, taki sam jak w kubelecie"
sudo mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml > /dev/null
sudo systemctl restart containerd
sudo systemctl enable containerd
gotowe "containerd: $(systemctl is-active containerd), $(grep -c 'SystemdCgroup = true' /etc/containerd/config.toml)× SystemdCgroup = true w /etc/containerd/config.toml"

krok "5/5 kubeadm, kubelet i kubectl ${K8S_MINOR} z pkgs.k8s.io"
# Poprawka błędu 1: katalog na klucze może nie istnieć na świeżym Ubuntu 22.04
sudo mkdir -p /etc/apt/keyrings
# Poprawka błędu 2: curl jako zwykły user, gpg jako root przez sudo tee
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" | gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
gotowe "Zainstalowano kubeadm $(kubeadm version -o short), kubelet $(kubelet --version | awk '{print $2}'), kubectl – wersje zablokowane (apt-mark hold)"
printf '  kubelet restartuje się co kilka sekund, dopóki kubeadm init/join nie da mu konfiguracji – to normalne\n'
