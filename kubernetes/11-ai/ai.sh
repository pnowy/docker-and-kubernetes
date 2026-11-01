#!/usr/bin/env bash
# Sekcja 11 (dodatek) – AI w pracy z Kubernetesem: weryfikacja manifestów od AI i diagnostyka z k8sgpt.
cd "$(dirname "$0")" || exit 1

# --- Narzędzia (jump-box, Linux amd64; macOS: brew install kubeconform kube-linter k8sgpt) ---
curl -sL https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-amd64.tar.gz | tar xz kubeconform
curl -sL -o kube-linter https://github.com/stackrox/kube-linter/releases/download/v0.8.3/kube-linter-linux && chmod +x kube-linter
curl -sL https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.4.41/k8sgpt_Linux_x86_64.tar.gz | tar xz k8sgpt
sudo mv kubeconform kube-linter k8sgpt /usr/local/bin/

# --- 1. Manifest od AI: najpierw walidacja, potem przegląd według checklista.md ---
kubeconform -strict -summary wygenerowany/notes-api.yaml        # extensions/v1beta1, serviceName/servicePort w Ingress v1
kubectl apply --dry-run=server -f wygenerowany/notes-api.yaml   # to samo zdanie API Servera klastra
kubectl explain ingress.spec.rules.http.paths.backend           # pola, które naprawdę istnieją: service.name, service.port

# Po poprawieniu apiVersion schemat przechodzi dalej – kube-linter znajduje problemy z dobrymi praktykami
sed 's#extensions/v1beta1#apps/v1#' wygenerowany/notes-api.yaml | kube-linter lint -   # latest, brak selector, root, brak zasobów
# Czego nie znajdzie żadne narzędzie: port 8080 i sonda /health – aplikacja słucha na 3000 i ma /healthz.
# To wie tylko ktoś, kto zna aplikację – dlatego każdy manifest od AI czyta człowiek.

# Wersja poprawiona: walidacja, lint, wdrożenie
kubeconform -strict -summary rozwiazanie/notes-api.yaml
kube-linter lint rozwiazanie/notes-api.yaml                     # zostaje no-anti-affinity – na 1 węźle bez znaczenia
kubectl apply --dry-run=server -f rozwiazanie/notes-api.yaml
kubectl diff -f rozwiazanie/notes-api.yaml                      # co dokładnie zmieni się w klastrze
kubectl apply -f rozwiazanie/notes-api.yaml

# --- 2. k8sgpt: diagnoza klastra (scenariusze awarii z sekcji 10) ---
kubectl create namespace awarie
kubectl apply -f ../10-troubleshooting/scenariusze/
sleep 45
k8sgpt analyze --namespace awarie                 # wbudowane analizatory, bez AI – wynik jak z kubectl describe
k8sgpt analyze --namespace awarie --filter=Pod    # tylko Pody
# Z wyjaśnieniem od modelu językowego (wysyła opis błędów do dostawcy – nie na klastrze z danymi firmy bez zgody):
#   k8sgpt auth add --backend anthropic --model <model>     # albo: --backend ollama (model lokalny)
#   k8sgpt analyze --namespace awarie --explain --anonymize
kubectl delete namespace awarie

# --- 3. kubectl-ai: agent, który sam wykonuje polecenia kubectl ---
# curl -sSL https://raw.githubusercontent.com/GoogleCloudPlatform/kubectl-ai/main/install.sh | bash
# Agent działa z uprawnieniami Twojego kubeconfiga – dawaj mu konto tylko do odczytu (sekcja 8, ClusterRole view):
#   kubectl-ai --llm-provider=<dostawca> --kubeconfig ~/.kube/agent-view.conf "dlaczego Pody w namespace awarie nie działają?"
