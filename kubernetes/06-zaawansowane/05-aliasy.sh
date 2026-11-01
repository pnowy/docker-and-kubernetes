# shellcheck shell=bash
# Dopisz do ~/.bashrc lub ~/.zshrc (albo: source 05-aliasy.sh)
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klogs='kubectl logs -f'

# Przełączanie kontekstu między klastrami:
#   kubectl config get-contexts
#   kubectl config use-context moj-klaster
#   kubectl config set-context --current --namespace=moj-namespace
