#!/usr/bin/env bash
# Przygotowanie jump-boxa (Ubuntu 24.04) krok po kroku – kopiuj polecenia do terminala POJEDYNCZO i patrz na wynik.
# Po każdej części sprawdzenie: ./tools-setup-automated.sh check <krok>   (krok w nagłówku części, np. check docker)
# Tę samą instalację automatycznie robi: ./tools-setup-automated.sh <krok>

# ============================================================================
# 1. Powłoka bash: starship, zoxide, fzf, hstr, autouzupełnianie     (check shell)
# ============================================================================

# 1.1 Pakiety z Ubuntu
sudo apt-get update
sudo apt-get install -y git curl unzip jq tree bash-completion fzf zoxide hstr xclip

# 1.2 Uzupełnianie kubectx/kubens – bash-completion wczytuje pliki z tego katalogu przy pierwszym Tab
mkdir -p ~/.local/share/bash-completion/completions
curl -fsSLo ~/.local/share/bash-completion/completions/kubectx https://raw.githubusercontent.com/ahmetb/kubectx/v0.11.0/completion/kubectx.bash
curl -fsSLo ~/.local/share/bash-completion/completions/kubens  https://raw.githubusercontent.com/ahmetb/kubectx/v0.11.0/completion/kubens.bash

# 1.3 starship – prompt z kontekstem Dockera i klastra Kubernetes
curl -fsSL https://starship.rs/install.sh | sh -s -- -y
mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
# Użytkownik zawsze, nie tylko po SSH albo jako root
[username]
show_always = true
format = '[👤 $user]($style) in '

# Kontekst Dockera zawsze, nie tylko obok compose.yaml / Dockerfile
[docker_context]
only_with_files = false
format = 'via [🐳 $context]($style) '

# Kontekst i namespace klastra: ☸ minikube (notes)
[kubernetes]
disabled = false
style = 'bold #fe8019'
format = '[$symbol$context( \($namespace\))]($style) '

# Kontekst z "prod" w nazwie na czerwono – ostrzeżenie przed delete/apply
[[kubernetes.contexts]]
context_pattern = ".*prod.*"
style = "bold red"
EOF

# 1.4 Konfiguracja basha: autouzupełnianie docker, kubectl, minikube, kind, helm i aliasy d, k, kctx, kns, Tab z menu, zoxide, fzf, hstr (Ctrl+R), pbcopy/pbpaste, starship
cat >> ~/.bashrc <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
source /usr/share/bash-completion/bash_completion
for t in docker kubectl minikube kind helm; do command -v $t > /dev/null && source <($t completion bash); done
alias d=docker k=kubectl kctx=kubectx kns=kubens
alias up='cd ..'
# Pliki uzupełniania kubectx/kubens rejestrują też kctx i kns – wczytane od razu, bo leniwe ładowanie szuka tylko po nazwie polecenia
for f in ~/.local/share/bash-completion/completions/kube{ctx,ns}; do [[ -f $f ]] && source "$f"; done
complete -o default -F __start_docker d
complete -o default -F __start_kubectl k
# Tab: od razu lista możliwości, kolejne Tab przechodzą po nich; strzałki ↑↓ szukają w historii po wpisanym początku
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'TAB: menu-complete'
bind '"\e[Z": menu-complete-backward'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
eval "$(zoxide init bash)"
f=/usr/share/doc/fzf/examples/key-bindings.bash; [[ -f $f ]] && source $f
# hstr na Ctrl+R (fzf zostaje: Ctrl+T pliki, Alt+C katalogi); wariant bez TIOCSTI – jądro Ubuntu 24.04 go blokuje
alias hh=hstr
export HSTR_CONFIG=hicolor HSTR_TIOCSTI=n HISTCONTROL=ignoreboth HISTFILESIZE=10000 HISTSIZE=10000
shopt -s histappend
export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"   # wspólna historia wszystkich okien terminala
hstrnotiocsti() { { READLINE_LINE="$( { </dev/tty hstr ${READLINE_LINE}; } 2>&1 1>&3 3>&- )"; } 3>&1; READLINE_POINT=${#READLINE_LINE}; }
[[ $- == *i* ]] && bind -x '"\C-r": "hstrnotiocsti"'
# pbcopy/pbpaste jak na Macu: na pulpicie RDP schowek X (xclip); po SSH bez X – sekwencja OSC 52 do terminala laptopa (Ghostty, iTerm2, Windows Terminal)
pbcopy() { if [[ -n ${DISPLAY:-} ]]; then xclip -selection clipboard; else printf '\e]52;c;%s\a' "$(base64 -w0)" > /dev/tty; fi; }
alias pbpaste='xclip -selection clipboard -o'
eval "$(starship init bash)"
EOF

# 1.5 Nowa konfiguracja w bieżącej powłoce i sprawdzenie
source ~/.bashrc
cd /tmp && cd ~ && z tmp && pwd   # /tmp – zoxide pamięta odwiedzone katalogi

# ============================================================================
# 2. Docker Engine, Scout, lazydocker, dive, trivy    (check docker)        wg https://docs.docker.com/engine/install/ubuntu/
# ============================================================================

# 2.1 Klucz GPG i repozytorium apt Dockera
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<SOURCES
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
SOURCES

# 2.2 Docker Engine z pluginami Buildx i Compose
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl status docker --no-pager      # active (running)

# 2.1–2.2 w wersji skrótowej: oficjalny skrypt get.docker.com robi to samo – repozytorium apt Dockera
#     i te same pakiety (Engine, Buildx, Compose). Wybierz JEDNĄ drogę: 2.1–2.2 albo ten skrypt.
#     Docker zaleca go tylko do środowisk testowych: instaluje zawsze najnowszą wersję i nie aktualizuje istniejącej instalacji.
# curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
# sudo sh /tmp/get-docker.sh --dry-run       # podgląd: jakie polecenia wykona
# sudo sh /tmp/get-docker.sh

# 2.3 Praca bez sudo – grupa docker daje uprawnienia równoważne root; działa od następnego logowania
#     Najpierw sprawdź: jeśli wypisze "docker", użytkownik już jest w grupie – pomiń usermod i newgrp
id -nG "$USER" | grep -ow docker
sudo usermod -aG docker "$USER"
newgrp docker                                # albo wyloguj się i zaloguj ponownie
docker run --rm hello-world                  # Hello from Docker!
docker compose version

# 2.4 lazydocker – terminalowy UI do kontenerów, obrazów i logów (jak k9s dla Dockera)
curl -fsSL https://github.com/jesseduffield/lazydocker/releases/download/v0.25.2/lazydocker_0.25.2_Linux_x86_64.tar.gz | tar -xz -C /tmp lazydocker
sudo install /tmp/lazydocker /usr/local/bin/lazydocker
lazydocker --version

# 2.5 dive – warstwy obrazu: co dodała każda instrukcja Dockerfile i ile miejsca marnuje
curl -Lo /tmp/dive.deb https://github.com/wagoodman/dive/releases/download/v0.13.1/dive_0.13.1_linux_amd64.deb
sudo apt-get install -y /tmp/dive.deb
dive --version

# 2.6 trivy – skaner podatności (CVE) w obrazach i błędów konfiguracji w Dockerfile/manifestach (repozytorium apt Aqua Security)
sudo apt-get install -y gpg
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
sudo tee /etc/apt/sources.list.d/trivy.sources > /dev/null <<'SOURCES'
Types: deb
URIs: https://aquasecurity.github.io/trivy-repo/deb
Suites: generic
Components: main
Signed-By: /usr/share/keyrings/trivy.gpg
SOURCES
sudo apt-get update
sudo apt-get install -y trivy
trivy --version

# 2.7 Docker Scout – podatności, SBOM i podpowiedzi obrazu bazowego (docker scout quickview/cves/recommendations)
#     Na Linuksie nie ma pakietu apt: plugin CLI do katalogu systemowego; analiza wymaga docker login (darmowe konto Docker Hub)
curl -fsSL https://github.com/docker/scout-cli/releases/download/v1.29.0/docker-scout_1.29.0_linux_amd64.tar.gz | tar -xz -C /tmp docker-scout
sudo install -D -m 0755 /tmp/docker-scout /usr/local/lib/docker/cli-plugins/docker-scout
docker scout version

# ============================================================================
# 3. Narzędzia Kubernetes: kubectl, minikube, kind, helm, k9s, kubectx/kubens     (check k8s)
# ============================================================================

# 3.1 kubectl – najnowsza stabilna wersja
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
kubectl version --client

# 3.2 minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
minikube version

# 3.3 kind
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
sudo install kind /usr/local/bin/kind && rm kind
kind version

# 3.4 Helm 4
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
helm version

# 3.5 k9s – terminalowy UI do klastra (pakiet .deb z GitHub Releases)
curl -Lo /tmp/k9s.deb https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb
sudo apt-get install -y /tmp/k9s.deb
k9s version

# 3.6 kubectx i kubens – szybkie przełączanie klastrów i namespace'ów
for t in kubectx kubens; do
  curl -fsSL https://github.com/ahmetb/kubectx/releases/download/v0.11.0/${t}_v0.11.0_linux_x86_64.tar.gz | tar -xz -C /tmp $t
  sudo install /tmp/$t /usr/local/bin/$t
done
kubectx --version

source ~/.bashrc         # wczytuje autouzupełnianie kubectl, helm, minikube, kind (dopiero teraz są zainstalowane)

# ============================================================================
# 4. Klaster minikube – sekcje Kubernetes 1–6 i 8–11     (check minikube)
# ============================================================================

# --cni=calico: domyślna sieć minikube nie egzekwuje NetworkPolicy (sekcja 4)
# Jump-box z 16 GB RAM: --cpus=4 --memory=8192 (stos monitoringu z sekcji 9 potrzebuje ok. 2 GB); z 8 GB: --cpus=2 --memory=4096
free -g
minikube start --driver=docker --cni=calico --cpus=4 --memory=8192
minikube addons enable metrics-server   # kubectl top, HPA
minikube addons enable ingress          # kontroler Ingress NGINX
minikube addons enable headlamp         # UI klastra
kubectl get nodes                       # minikube   Ready   control-plane

# ============================================================================
# 5. SSH z jump-boxa do maszyn kubeadm     (check ssh)
# ============================================================================

# 5.1 Klucz SSH jump-boxa (Enter na wszystkie pytania)
ssh-keygen -t ed25519

# 5.2 Aliasy maszyn – zamiast adresów IP piszesz ssh k8s-cp
cat >> ~/.ssh/config <<'EOF'
Host k8s-cp
  HostName 10.4.0.50
Host k8s-worker1
  HostName 10.4.0.100
Host k8s-worker2
  HostName 10.4.0.200
Host k8s-cp k8s-worker1 k8s-worker2
  User kurs
  IdentityFile ~/.ssh/id_ed25519
  StrictHostKeyChecking accept-new
EOF
chmod 600 ~/.ssh/config

# 5.3 Klucz na każdej maszynie – ostatni raz podajesz hasło
for h in k8s-cp k8s-worker1 k8s-worker2; do ssh-copy-id $h; done
for h in k8s-cp k8s-worker1 k8s-worker2; do ssh $h hostname; done   # nazwy maszyn bez pytania o hasło

# 5.4 Nadal pyta o hasło? Obraz VM wyłącza klucze (sudo sshd -T: pubkeyauthentication no) – włącz je na każdej maszynie
# sed w miejscu istniejącej linii: sshd bierze pierwszą wartość, nowy plik w sshd_config.d przegrywa z "no" przed Include
for h in k8s-cp k8s-worker1 k8s-worker2; do
  ssh -t $h "sudo grep -rlis pubkeyauthentication /etc/ssh/sshd_config /etc/ssh/sshd_config.d | xargs -r sudo sed -i -E 's/^#?[[:space:]]*PubkeyAuthentication.*/PubkeyAuthentication yes/I' && sudo sshd -t && sudo systemctl restart ssh"
done

# ============================================================================
# 6. Klaster kubeadm: 1 Control Plane + 2 workery     (check kubeadm)
#    Szczegóły i wyjaśnienia: kubernetes/07-kubeadm/README.md
# ============================================================================

# 6.1 Skrypty na maszyny
cd ~/docker-and-kubernetes/kubernetes/07-kubeadm
for h in k8s-cp k8s-worker1 k8s-worker2; do scp common.sh install_master.sh install_worker_nodes.sh deploy_nginx.sh $h:; done

# 6.2 Control Plane: containerd, kubeadm, kubeadm init, Calico – kilka minut (sudo pyta o hasło)
ssh -t k8s-cp ./install_master.sh

# 6.3 Workery: przygotowanie węzła i dołączenie do klastra poleceniem kubeadm join z Control Plane
ssh -t k8s-cp 'sudo kubeadm token create --print-join-command > info_join_worker'
JOIN=$(ssh k8s-cp cat info_join_worker)
echo "$JOIN"
ssh -t k8s-worker1 ./install_worker_nodes.sh
ssh -t k8s-worker1 "sudo $JOIN"
ssh -t k8s-worker2 ./install_worker_nodes.sh
ssh -t k8s-worker2 "sudo $JOIN"

# 6.4 Węzły Ready, gdy Calico wystartuje na każdym z nich (Ctrl+C kończy obserwację)
ssh -t k8s-cp kubectl get nodes -w

# ============================================================================
# 7. kubectl na jump-boksie: kontekst kubeadm obok minikube     (check kubeconfig)
# ============================================================================

scp k8s-cp:.kube/config ~/.kube/kubeadm.conf
KUBECONFIG=~/.kube/kubeadm.conf kubectl config rename-context kubernetes-admin@kubernetes kubeadm
cp ~/.kube/config ~/.kube/config.bak
KUBECONFIG=~/.kube/config:~/.kube/kubeadm.conf kubectl config view --flatten > /tmp/kubeconfig && mv /tmp/kubeconfig ~/.kube/config
chmod 600 ~/.kube/config
kubectl config get-contexts            # minikube i kubeadm
kubectl --context kubeadm get nodes    # 3 węzły Ready
kubectx kubeadm                        # prompt: ☸ kubeadm
kubectx minikube

# Wszystko naraz: ./tools-setup-automated.sh check

# ============================================================================
# 8. (opcjonalnie) VS Code na pulpicie jump-boxa – praca przez RDP     (check vscode)
#    Z laptopa wygodniej: VS Code Remote-SSH (README) – wtedy ten krok jest niepotrzebny
# ============================================================================

# 8.1 Klucz i repozytorium apt Microsoftu – aktualizacje VS Code razem z apt upgrade
sudo apt-get install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<'SOURCES'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
SOURCES

# 8.2 VS Code i rozszerzenia: YAML (walidacja manifestów), Kubernetes (widok klastra), Container Tools (Dockerfile, compose)
sudo apt-get update
sudo apt-get install -y code
code --install-extension redhat.vscode-yaml
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension ms-azuretools.vscode-containers
code ~/docker-and-kubernetes      # w terminalu na pulpicie RDP – otwiera okno VS Code

# ============================================================================
# 9. (opcjonalnie) Node.js i uv – aplikacje szkoleniowe bez Dockera, np. do porównania z kontenerem     (check dev)
# ============================================================================

# 9.1 Node.js 24 z repozytorium NodeSource – Ubuntu 24.04 ma v18, a app-node wymaga node >= 24
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version                    # v24.x

# 9.2 uv – Python i zależności w jednym narzędziu (instaluje do ~/.local/bin, już w PATH z części 1)
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
uv --version

# 9.3 Aplikacje bez Dockera (STORAGE=json – bez bazy danych); Ctrl+C kończy
cd ~/docker-and-kubernetes/app-node && npm ci && npm run dev-json                 # http://localhost:3000
cd ~/docker-and-kubernetes/app-python/src && STORAGE=json uv run --python 3.12 --with-requirements ../requirements.txt uvicorn main:app --port 8000
