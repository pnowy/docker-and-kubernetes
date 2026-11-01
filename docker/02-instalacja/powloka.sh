#!/usr/bin/env bash
# Dodatek (poza ALX): wygodna powłoka na Linuksie (Ubuntu 24.04) – autouzupełnianie, zsh + oh-my-zsh, starship.
# Po instalacji Dockera (install-docker-ubuntu.sh). Wykonuj polecenia pojedynczo. macOS: brew install starship

# 1. Autouzupełnianie w bashu – wystarczy, jeśli zostajesz przy bashu
#    (pakiet docker-ce-cli dostarcza gotowy plik /usr/share/bash-completion/completions/docker)
sudo apt-get install -y bash-completion
echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc   # w ~/.bashrc root-a i części obrazów tego brak
source ~/.bashrc
# test: docker con<TAB><TAB>  →  config  container  context

# 2. zsh i oh-my-zsh (--unattended: nie zmienia powłoki i nie uruchamia zsh w trakcie)
sudo apt-get install -y zsh git curl
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo chsh -s "$(command -v zsh)" "$USER"     # zsh domyślną powłoką – od następnego logowania

# 3. Wtyczki oh-my-zsh: docker (autouzupełnianie docker i docker compose + aliasy), git
sed -i 's/^plugins=(.*)/plugins=(git docker)/' ~/.zshrc

# 4. starship – prompt z kontekstem Dockera (a w części Kubernetes także klastra)
curl -sS https://starship.rs/install.sh | sh -s -- -y
sed -i 's/^ZSH_THEME=.*/ZSH_THEME=""/' ~/.zshrc   # motyw oh-my-zsh wyłączony – prompt rysuje starship
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
# Kontekst Dockera zawsze, nie tylko obok compose.yaml / Dockerfile (kontekst "default" starship ukrywa)
[docker_context]
only_with_files = false
format = 'via [🐳 $context]($style) '
EOF

# 5. Sprawdzenie – nowa powłoka
exec zsh
docker context create zdalny --docker host=ssh://uzytkownik@inny-host   # tylko wpis, bez połączenia
docker context use zdalny          # prompt: via 🐳 zdalny
docker context use default         # prompt bez 🐳
docker context rm zdalny
