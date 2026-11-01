#!/usr/bin/env bash
# Automatyczne przygotowanie jump-boxa (Ubuntu 24.04): te same kroki co w tools-setup-manual.sh, plus sprawdzenie.
#
# Instalacja: ./tools-setup-automated.sh <krok>...   np. ./tools-setup-automated.sh shell docker   (all = wszystkie po kolei)
# Sprawdzenie: ./tools-setup-automated.sh check [krok]...   np. ./tools-setup-automated.sh check docker   (bez kroku = wszystkie)
# Kroki:      shell docker k8s minikube ssh kubeadm kubeconfig
# Opcjonalne: vscode – VS Code na pulpicie jump-boxa (RDP); dev – Node.js i uv do uruchomienia aplikacji bez Dockera
#             (opcjonalne nie wchodzą do all ani do check bez kroku)
# Zmienne:    CP_IP, WORKER_IPS, VM_USER – adresy i użytkownik maszyn kubeadm; UPDATE=1 – przeinstaluj narzędzia;
#             DOCKER_INSTALL=script – Docker skryptem get.docker.com zamiast ręcznej konfiguracji repozytorium
#
# Każdy krok można powtórzyć: pomija to, co już jest, i kończy się sprawdzeniem (✓/✗ + podpowiedź, jak naprawić).
set -euo pipefail
cd "$(dirname "$0")"

CP_IP="${CP_IP:-10.4.0.50}"
WORKER_IPS="${WORKER_IPS:-10.4.0.100 10.4.0.200}"
VM_USER="${VM_USER:-kurs}"
UPDATE="${UPDATE:-0}"
KIND_VERSION="${KIND_VERSION:-v0.33.0}"
KUBECTX_VERSION="${KUBECTX_VERSION:-v0.11.0}"
LAZYDOCKER_VERSION="${LAZYDOCKER_VERSION:-0.25.2}"
DIVE_VERSION="${DIVE_VERSION:-0.13.1}"
SCOUT_VERSION="${SCOUT_VERSION:-1.29.0}"
NODE_MAJOR="${NODE_MAJOR:-24}"
DOCKER_INSTALL="${DOCKER_INSTALL:-repo}"
KUBEADM_DIR="../kubernetes/07-kubeadm"
export PATH="$HOME/.local/bin:$PATH"

# Aliasy SSH maszyn kubeadm (wpisy w ~/.ssh/config z kroku ssh)
CP=k8s-cp
WORKERS=()
i=1; for _ in $WORKER_IPS; do WORKERS+=("k8s-worker$i"); i=$((i + 1)); done

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
skip() { printf '    \033[0;32m✓ %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31mBłąd: %s\033[0m\n' "$*" >&2; exit 1; }
need() { [[ "$UPDATE" == 1 ]] || ! command -v "$1" > /dev/null; }   # true = trzeba zainstalować

# Zastępuje blok między znacznikami w pliku – ponowne uruchomienie nie dopisuje duplikatów
managed_block() {
  local file=$1 start="# >>> alx tools-setup >>>" end="# <<< alx tools-setup <<<"
  touch "$file"
  sed -i "/^$start\$/,/^$end\$/d" "$file"
  { echo "$start"; cat; echo "$end"; } >> "$file"
}

# Docker bez sudo zaraz po dodaniu do grupy docker (bez wylogowania): przez sg
as_docker() {
  if docker info > /dev/null 2>&1; then "$@"
  elif id -nG "$USER" | grep -qw docker; then sg docker -c "$(printf '%q ' "$@")"
  else echo "Brak dostępu do Dockera – uruchom najpierw: $0 docker" >&2; return 1
  fi
}

step_shell() {
  log "Powłoka bash: starship, zoxide, fzf, hstr, autouzupełnianie"
  sudo apt-get update -qq
  sudo apt-get install -y -qq git curl unzip jq tree bash-completion fzf zoxide hstr xclip

  # kubectx/kubens: bash-completion wczytuje pliki z tego katalogu przy pierwszym Tab po nazwie polecenia
  local comp=~/.local/share/bash-completion/completions
  mkdir -p "$comp"
  for t in kubectx kubens; do
    curl -fsSLo "$comp/$t" "https://raw.githubusercontent.com/ahmetb/kubectx/$KUBECTX_VERSION/completion/$t.bash"
  done

  if need starship; then curl -fsSL https://starship.rs/install.sh | sh -s -- -y > /dev/null; else skip "starship"; fi
  mkdir -p ~/.config
  if [[ -f ~/.config/starship.toml ]]; then skip "~/.config/starship.toml (zostawiam istniejący)"; else
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
  fi

  managed_block ~/.bashrc <<'EOF'
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
}

step_docker() {
  log "Docker Engine z pluginami Buildx, Compose i Scout, lazydocker, dive, trivy"
  if command -v docker > /dev/null; then skip "docker $(docker --version | cut -d' ' -f3 | tr -d ,)"
  elif [[ $DOCKER_INSTALL == script ]]; then
    # Skrypt Dockera konfiguruje to samo repozytorium apt i instaluje te same pakiety co gałąź niżej
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
  else
    sudo apt-get install -y -qq ca-certificates curl
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
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
  # Grupa docker = uprawnienia równoważne root; działa od następnego logowania (w tym skrypcie: przez sg)
  if id -nG "$USER" | grep -qw docker; then skip "użytkownik w grupie docker"; else sudo usermod -aG docker "$USER"; fi

  # Przypięte wersje zamiast GitHub API "latest" – cała grupa za jednym NAT-em szybko wyczerpuje limit API
  local tmp; tmp=$(mktemp -d)
  if need lazydocker; then
    curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/download/v$LAZYDOCKER_VERSION/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" | tar -xz -C "$tmp" lazydocker
    sudo install -m 0755 "$tmp/lazydocker" /usr/local/bin/lazydocker
  else skip "lazydocker"; fi
  if need dive; then
    curl -fsSLo "$tmp/dive.deb" "https://github.com/wagoodman/dive/releases/download/v$DIVE_VERSION/dive_${DIVE_VERSION}_linux_amd64.deb"
    sudo apt-get install -y -qq "$tmp/dive.deb"
  else skip "dive"; fi
  # Scout na Linuksie nie ma pakietu apt – plugin CLI w katalogu systemowym, widoczny dla wszystkich użytkowników
  if docker scout version > /dev/null 2>&1; then skip "docker scout"; else
    curl -fsSL "https://github.com/docker/scout-cli/releases/download/v$SCOUT_VERSION/docker-scout_${SCOUT_VERSION}_linux_amd64.tar.gz" | tar -xz -C "$tmp" docker-scout
    sudo install -D -m 0755 "$tmp/docker-scout" /usr/local/lib/docker/cli-plugins/docker-scout
  fi
  rm -rf "$tmp"
  if need trivy; then
    sudo apt-get install -y -qq gpg
    curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/trivy.gpg
    sudo tee /etc/apt/sources.list.d/trivy.sources > /dev/null <<'SOURCES'
Types: deb
URIs: https://aquasecurity.github.io/trivy-repo/deb
Suites: generic
Components: main
Signed-By: /usr/share/keyrings/trivy.gpg
SOURCES
    sudo apt-get update -qq
    sudo apt-get install -y -qq trivy
  else skip "trivy"; fi
}

step_dev() {
  log "Node.js $NODE_MAJOR i uv – aplikacje app-node i app-python bez Dockera"
  # NodeSource zamiast nodejs z Ubuntu 24.04 (v18) – app-node wymaga node >= 24
  if need node; then
    curl -fsSL "https://deb.nodesource.com/setup_$NODE_MAJOR.x" | sudo -E bash - > /dev/null
    sudo apt-get install -y -qq nodejs
  else skip "node $(node --version)"; fi
  # ~/.local/bin jest już w PATH z kroku shell – instalator nie musi zmieniać ~/.bashrc
  if need uv; then curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh > /dev/null
  else skip "$(uv --version)"; fi
}

step_vscode() {
  log "VS Code z repozytorium Microsoftu"
  if command -v code > /dev/null; then skip "code $(code --version 2> /dev/null | sed -n 1p)"; else
    sudo apt-get install -y -qq wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /usr/share/keyrings/microsoft.gpg
    sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<'SOURCES'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
SOURCES
    sudo apt-get update -qq
    sudo apt-get install -y -qq code
  fi
  # Rozszerzenia: podpowiedzi i walidacja manifestów YAML, widok klastra, Dockerfile/compose
  for e in redhat.vscode-yaml ms-kubernetes-tools.vscode-kubernetes-tools ms-azuretools.vscode-containers; do
    if code --list-extensions 2> /dev/null | grep -qix "$e"; then skip "rozszerzenie $e"
    else code --install-extension "$e" > /dev/null 2>&1 || printf '    \033[1;33m! nie udało się zainstalować %s\033[0m\n' "$e"; fi
  done
}

step_k8s() {
  log "Narzędzia Kubernetes: kubectl, minikube, kind, helm, k9s, kubectx/kubens"
  local tmp; tmp=$(mktemp -d)
  if need kubectl; then
    curl -fsSLo "$tmp/kubectl" "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -m 0755 "$tmp/kubectl" /usr/local/bin/kubectl
  else skip "kubectl"; fi
  if need minikube; then
    curl -fsSLo "$tmp/minikube" https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install -m 0755 "$tmp/minikube" /usr/local/bin/minikube
  else skip "minikube"; fi
  if need kind; then
    curl -fsSLo "$tmp/kind" "https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-linux-amd64"
    sudo install -m 0755 "$tmp/kind" /usr/local/bin/kind
  else skip "kind"; fi
  if need helm; then curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash > /dev/null
  else skip "helm"; fi
  if need k9s; then
    curl -fsSLo "$tmp/k9s.deb" https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb
    sudo apt-get install -y -qq "$tmp/k9s.deb"
  else skip "k9s"; fi
  for t in kubectx kubens; do
    if need $t; then
      curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/$KUBECTX_VERSION/${t}_${KUBECTX_VERSION}_linux_x86_64.tar.gz" | tar -xz -C "$tmp" $t
      sudo install -m 0755 "$tmp/$t" /usr/local/bin/$t
    else skip "$t"; fi
  done
  rm -rf "$tmp"
}

step_minikube() {
  log "Klaster minikube (sekcje Kubernetes 1–6 i 8–11)"
  command -v minikube > /dev/null || die "brak minikube – uruchom najpierw: $0 k8s"
  if as_docker minikube status > /dev/null 2>&1; then skip "minikube działa"; else
    # Stos monitoringu z sekcji 9 potrzebuje ok. 2 GB – na jump-boksie z 16 GB RAM dajemy klastrowi więcej
    local cpus=2 mem=4096
    (( $(free -g | awk '/^Mem:/{print $2}') >= 15 )) && { cpus=4; mem=8192; }
    # --cni=calico: domyślna sieć minikube nie egzekwuje NetworkPolicy (sekcja 4)
    as_docker minikube start --driver=docker --cni=calico --cpus=$cpus --memory=$mem
  fi
  for a in metrics-server ingress headlamp; do as_docker minikube addons enable $a > /dev/null; done
  kubectl config use-context minikube > /dev/null
}

step_ssh() {
  log "SSH z jump-boxa do maszyn kubeadm: klucz, aliasy ${CP} ${WORKERS[*]}"
  [[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
  local entries="Host $CP"$'\n'"  HostName $CP_IP"$'\n' n=0
  for ip in $WORKER_IPS; do entries+="Host ${WORKERS[$n]}"$'\n'"  HostName $ip"$'\n'; n=$((n + 1)); done
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  # accept-new: pierwszy odcisk klucza hosta zapisywany bez pytania, zmieniony – odrzucany
  managed_block ~/.ssh/config <<EOF
${entries}Host $CP ${WORKERS[*]}
  User $VM_USER
  IdentityFile ~/.ssh/id_ed25519
  StrictHostKeyChecking accept-new
EOF
  chmod 600 ~/.ssh/config
  for h in $CP "${WORKERS[@]}"; do
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$h" true 2> /dev/null; then skip "$h – logowanie kluczem działa"; else
      echo "    $h: podaj hasło użytkownika $VM_USER (jednorazowo, kopiowanie klucza)"
      ssh-copy-id -i ~/.ssh/id_ed25519.pub "$h"
    fi
    # klucz skopiowany, a logowanie dalej hasłem: obraz VM ma PubkeyAuthentication no – sed w miejscu, bo sshd bierze pierwszą wartość
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$h" true 2> /dev/null; then
      echo "    $h: serwer nie przyjmuje kluczy – włączam PubkeyAuthentication (hasło ssh, potem sudo)"
      ssh -t "$h" "sudo grep -rlis pubkeyauthentication /etc/ssh/sshd_config /etc/ssh/sshd_config.d | xargs -r sudo sed -i -E 's/^#?[[:space:]]*PubkeyAuthentication.*/PubkeyAuthentication yes/I' && sudo sshd -t && sudo systemctl restart ssh"
    fi
  done
}

step_kubeadm() {
  log "Klaster kubeadm: Control Plane $CP_IP, workery $WORKER_IPS (kilka minut na maszynę)"
  [[ -f $KUBEADM_DIR/common.sh ]] || die "brak skryptów w $KUBEADM_DIR"
  for h in $CP "${WORKERS[@]}"; do
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$h" true 2> /dev/null || die "brak logowania kluczem do $h – uruchom: $0 ssh"
    scp -q "$KUBEADM_DIR"/{common.sh,install_master.sh,install_worker_nodes.sh,deploy_nginx.sh} "$h:"
  done

  # -t: sudo na maszynie może zapytać o hasło
  if ssh "$CP" test -f /etc/kubernetes/admin.conf; then skip "$CP – Control Plane już zainicjalizowany"; else
    ssh -t "$CP" ./install_master.sh
  fi

  # Token z install_master.sh wygasa po 24 h – przed dołączaniem zawsze nowe polecenie join
  ssh -t "$CP" 'sudo kubeadm token create --print-join-command > info_join_worker'
  local join; join=$(ssh "$CP" cat info_join_worker)
  for h in "${WORKERS[@]}"; do
    if ssh "$h" test -f /etc/kubernetes/kubelet.conf; then skip "$h – już w klastrze"; else
      ssh -t "$h" ./install_worker_nodes.sh
      ssh -t "$h" "sudo $join"
    fi
  done

  echo "    czekam, aż Calico wystartuje na wszystkich węzłach…"
  ssh "$CP" kubectl wait --for=condition=Ready nodes --all --timeout=600s > /dev/null || true
  ssh "$CP" kubectl get nodes -o wide
}

step_kubeconfig() {
  log "Kontekst kubeadm w ~/.kube/config jump-boxa (obok minikube)"
  mkdir -p ~/.kube
  scp -q "$CP:.kube/config" ~/.kube/kubeadm.conf
  KUBECONFIG=~/.kube/kubeadm.conf kubectl config rename-context kubernetes-admin@kubernetes kubeadm > /dev/null 2>&1 || true
  if [[ -f ~/.kube/config ]]; then
    cp ~/.kube/config ~/.kube/config.bak
    # Stare wpisy z poprzedniego klastra kubeadm – po kubeadm reset certyfikaty są inne
    kubectl config delete-context kubeadm > /dev/null 2>&1 || true
    kubectl config delete-cluster kubernetes > /dev/null 2>&1 || true
    kubectl config delete-user kubernetes-admin > /dev/null 2>&1 || true
    KUBECONFIG=~/.kube/config:~/.kube/kubeadm.conf kubectl config view --flatten > ~/.kube/config.new
    mv ~/.kube/config.new ~/.kube/config
  else
    cp ~/.kube/kubeadm.conf ~/.kube/config
  fi
  chmod 600 ~/.kube/config
  kubectl config get-contexts
}

# --- Sprawdzenia: ✓/✗ dla każdego elementu kroku, na końcu podpowiedź, jak naprawić ---
FAILS=0
ok()   { printf '    \033[0;32m✓\033[0m %s\n' "$1"; }
bad()  { printf '    \033[1;31m✗\033[0m %s\n' "$1"; FAILS=$((FAILS + 1)); }
warn() { printf '    \033[1;33m!\033[0m %s\n' "$1"; }
chk()  { local d=$1; shift; if "$@" > /dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
# Wypisuje podpowiedzi tylko wtedy, gdy w bieżącym sprawdzeniu coś się nie udało
fix()  { (( FAILS > BEFORE )) || return 0; printf '    \033[1;33mJak naprawić:\033[0m\n'; printf '      %s\n' "$@"; }
ssh_q() { ssh -o BatchMode=yes -o ConnectTimeout=5 "$@"; }

check_shell() {
  log "Sprawdzenie: shell"; BEFORE=$FAILS
  chk "bash-completion" test -f /usr/share/bash-completion/bash_completion
  for t in starship zoxide fzf hstr xclip; do chk "$t" command -v $t; done
  chk "~/.config/starship.toml" test -f ~/.config/starship.toml
  chk "uzupełnianie kubectx i kubens" test -f ~/.local/share/bash-completion/completions/kubens
  chk "starship i zoxide w ~/.bashrc" bash -c 'grep -q "starship init bash" ~/.bashrc && grep -q "zoxide init bash" ~/.bashrc'
  # bez terminala (np. ssh bez -t) bash -i ostrzega o job control i edycji linii – to nie błędy konfiguracji
  chk "bash startuje bez błędów" bash -c '[[ -z "$(bash -i -c true 2>&1 > /dev/null | grep -v "job control\|terminal process group\|line editing not enabled")" ]]'
  [[ "$(getent passwd "$USER" | cut -d: -f7)" == */bash ]] || warn "powłoka logowania to nie bash: sudo usermod -s /bin/bash $USER"
  fix "$0 shell" "błędy przy starcie basha: bash -i -c true" "prompt bez zmian: source ~/.bashrc"
}

check_docker() {
  log "Sprawdzenie: docker"; BEFORE=$FAILS
  chk "polecenie docker" command -v docker
  chk "usługa docker działa" systemctl is-active --quiet docker
  chk "plugin compose" docker compose version
  chk "plugin buildx" docker buildx version
  chk "plugin scout" docker scout version
  chk "użytkownik $USER w grupie docker" bash -c 'id -nG "$USER" | grep -qw docker'
  if docker info > /dev/null 2>&1; then ok "docker bez sudo w tej sesji"
  elif command -v docker > /dev/null; then warn "docker bez sudo działa dopiero po ponownym zalogowaniu (albo: newgrp docker)"; fi
  chk "docker run hello-world" as_docker docker run --rm hello-world
  for t in lazydocker dive trivy; do chk "$t" command -v $t; done
  fix "$0 docker" "logi usługi: sudo systemctl status docker; sudo journalctl -u docker -n 50" \
    "repozytorium apt: cat /etc/apt/sources.list.d/docker.sources; sudo apt-get update"
}

check_dev() {
  log "Sprawdzenie: dev"; BEFORE=$FAILS
  chk "node >= $NODE_MAJOR" bash -c '(( $(node --version 2> /dev/null | sed "s/^v//; s/\..*//") >= '"$NODE_MAJOR"' ))'
  chk "npm" command -v npm
  chk "uv" bash -c 'command -v uv || test -x ~/.local/bin/uv'
  fix "$0 dev" "uv nie w PATH: source ~/.bashrc (krok shell dodaje ~/.local/bin)"
}

check_vscode() {
  log "Sprawdzenie: vscode"; BEFORE=$FAILS
  chk "polecenie code" command -v code
  chk "repozytorium apt VS Code" test -f /etc/apt/sources.list.d/vscode.sources
  for e in redhat.vscode-yaml ms-kubernetes-tools.vscode-kubernetes-tools ms-azuretools.vscode-containers; do
    chk "rozszerzenie $e" bash -c "code --list-extensions 2> /dev/null | grep -qix $e"
  done
  fix "$0 vscode" "uruchomienie na pulpicie RDP: code ~/docker-and-kubernetes"
}

check_k8s() {
  log "Sprawdzenie: k8s"; BEFORE=$FAILS
  for t in kubectl minikube kind helm k9s kubectx kubens; do chk "$t" command -v $t; done
  command -v kubectl > /dev/null && printf '      %s\n' "$(kubectl version --client 2> /dev/null | sed -n 1p)"
  fix "$0 k8s" "jedno narzędzie od nowa: UPDATE=1 $0 k8s"
}

check_minikube() {
  log "Sprawdzenie: minikube"; BEFORE=$FAILS
  chk "minikube działa" as_docker minikube status
  chk "kontekst minikube w ~/.kube/config" kubectl config get-contexts minikube
  chk "węzeł minikube Ready" kubectl --context minikube wait --for=condition=Ready node --all --timeout=10s
  chk "addon metrics-server" kubectl --context minikube -n kube-system get deploy metrics-server
  chk "addon ingress" kubectl --context minikube -n ingress-nginx get deploy ingress-nginx-controller
  chk "addon headlamp" kubectl --context minikube -n headlamp get deploy headlamp
  fix "$0 minikube" "logi: minikube logs | tail -50" "klaster od nowa: minikube delete && $0 minikube"
}

check_ssh() {
  log "Sprawdzenie: ssh"; BEFORE=$FAILS
  chk "klucz ~/.ssh/id_ed25519" test -f ~/.ssh/id_ed25519
  chk "aliasy w ~/.ssh/config" grep -q "^Host $CP\$" ~/.ssh/config
  for h in $CP "${WORKERS[@]}"; do chk "$h: logowanie kluczem" ssh_q "$h" true; done
  fix "$0 ssh" "czy maszyna odpowiada: nc -zv $CP_IP 22" "logowanie hasłem: ssh $VM_USER@$CP_IP" "klucze wyłączone na VM: ssh -t $CP sudo sshd -T | grep -i pubkey"
}

check_kubeadm() {
  log "Sprawdzenie: kubeadm"; BEFORE=$FAILS
  for h in $CP "${WORKERS[@]}"; do chk "$h: kubelet działa" ssh_q "$h" systemctl is-active --quiet kubelet; done
  chk "$CP: kubectl get nodes" ssh_q "$CP" kubectl get nodes
  local n=$((1 + ${#WORKERS[@]}))
  chk "$n węzły Ready" bash -c "[[ \$(ssh -o BatchMode=yes $CP kubectl get nodes --no-headers | grep -cw Ready) -eq $n ]]"
  chk "Calico dostępne (tigerastatus)" ssh_q "$CP" kubectl wait --for=condition=Available tigerastatus/calico --timeout=10s
  fix "$0 kubeadm" "węzły i Pody: ssh $CP 'kubectl get nodes; kubectl get pods -A | grep -v Running'" \
    "kubelet na węźle: ssh <węzeł> sudo journalctl -u kubelet -n 50"
}

check_kubeconfig() {
  log "Sprawdzenie: kubeconfig"; BEFORE=$FAILS
  chk "kontekst kubeadm w ~/.kube/config" kubectl config get-contexts kubeadm
  chk "kubectl --context kubeadm get nodes" kubectl --context kubeadm get nodes --request-timeout=5s
  fix "$0 kubeconfig" "adres API Servera: kubectl config view --minify --context kubeadm | grep server"
}

STEPS=(shell docker k8s minikube ssh kubeadm kubeconfig)
OPTIONAL=(vscode dev)
usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
valid() { [[ " ${STEPS[*]} ${OPTIONAL[*]} " == *" $1 "* ]] || { echo "Nieznany krok: $1" >&2; usage 1; }; }

[[ $# -gt 0 ]] || usage 1
case $1 in
  -h|--help|help) usage ;;
  check)
    shift; [[ $# -gt 0 ]] || set -- "${STEPS[@]}"
    for s in "$@"; do valid "$s"; done
    for s in "$@"; do "check_$s"; done ;;
  *)
    [[ $1 == all ]] && set -- "${STEPS[@]}"
    for s in "$@"; do valid "$s"; done
    for s in "$@"; do "step_$s"; "check_$s"; done ;;
esac

if (( FAILS == 0 )); then log "Wszystko OK. Nowa sesja (grupa docker, ~/.bashrc): wyloguj się i zaloguj ponownie"
else printf '\n\033[1;31m%d problem(y) – szczegóły i podpowiedzi wyżej\033[0m\n' "$FAILS"; exit 1; fi
