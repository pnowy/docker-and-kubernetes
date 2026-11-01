#!/usr/bin/env bash
# Dodatek (poza ALX): autouzupełnianie kubectl, minikube, kind, kubectx/kubens + kontekst klastra w prompcie (starship).
# Po ćwiczeniu 2.3 i konteksty.sh. zsh, oh-my-zsh i starship instalowaliśmy w części Docker:
# students/docker/02-instalacja/powloka.sh – jeśli ich nie masz, zacznij od tamtego skryptu albo zostań przy bashu (krok 1).

VER=v0.11.0   # wersja kubectx/kubens z konteksty.sh
RAW=https://raw.githubusercontent.com/ahmetb/kubectx/$VER/completion

# 1. bash: autouzupełnianie + alias k
sudo apt-get install -y bash-completion
cat >> ~/.bashrc <<'EOF'
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
source <(minikube completion bash)
source <(kind completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
EOF
sudo curl -fsSLo /usr/share/bash-completion/completions/kubectx $RAW/kubectx.bash
sudo curl -fsSLo /usr/share/bash-completion/completions/kubens  $RAW/kubens.bash
source ~/.bashrc
# test: kubectl get po<TAB>  ·  k describe node <TAB>  ·  kubens <TAB>

# 2. zsh: wtyczki oh-my-zsh kubectl (autouzupełnianie + aliasy k, kgp, kaf…), minikube, kind
sed -i 's/^plugins=(.*)/plugins=(git docker kubectl minikube kind)/' ~/.zshrc
# kubectx/kubens: pliki uzupełniania jako lokalna wtyczka – oh-my-zsh dodaje jej katalog do fpath
mkdir -p ~/.oh-my-zsh/custom/plugins/kubectx-completion
touch ~/.oh-my-zsh/custom/plugins/kubectx-completion/kubectx-completion.plugin.zsh
curl -fsSLo ~/.oh-my-zsh/custom/plugins/kubectx-completion/_kubectx $RAW/_kubectx.zsh
curl -fsSLo ~/.oh-my-zsh/custom/plugins/kubectx-completion/_kubens  $RAW/_kubens.zsh
sed -i 's/^plugins=(\(.*\))/plugins=(\1 kubectx-completion)/' ~/.zshrc

# 3. starship: moduł kubernetes jest domyślnie wyłączony – włącz go
mkdir -p ~/.config
cat >> ~/.config/starship.toml <<'EOF'

# Kontekst i namespace klastra: ☸ minikube (notes)
[kubernetes]
disabled = false
format = '[$symbol$context( \($namespace\))]($style) '

# Kontekst z "prod" w nazwie na czerwono – ostrzeżenie przed delete/apply
[[kubernetes.contexts]]
context_pattern = ".*prod.*"
style = "bold red"
EOF

# 4. Sprawdzenie – nowa powłoka
exec zsh
kubectx minikube          # prompt: ☸ minikube
kubens kube-system        # prompt: ☸ minikube (kube-system)
kgp                       # alias wtyczki = kubectl get pods
kubens default
