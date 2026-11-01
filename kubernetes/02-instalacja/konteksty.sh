#!/usr/bin/env bash
# Dodatek (poza ALX): kilka klastrów na jednym jump-boksie – konteksty kubectl, kubectx i kubens.
# Wykonuj w ćwiczeniu 2.5 przed krokiem 21 (usunięcie klastra), gdy obok minikube działa klaster kind. macOS: brew install kubectx

# A. Konteksty w czystym kubectl – każdy klaster to wpis w ~/.kube/config
kubectl config get-contexts                  # gwiazdka = bieżący; minikube i kind-lab-klaster
kubectl config current-context
kubectl config use-context kind-lab-klaster
kubectl get nodes                            # 3 węzły kind
kubectl config use-context minikube
kubectl get nodes                            # 1 węzeł minikube
kubectl --context kind-lab-klaster get nodes # jednorazowo, bez przełączania

# Domyślny namespace bieżącego kontekstu
kubectl config set-context --current --namespace=kube-system
kubectl get pods                             # Pody z kube-system bez -n
kubectl config set-context --current --namespace=default

# B. Instalacja kubectx i kubens (Linux x86_64, wersja z github.com/ahmetb/kubectx/releases)
# Alternatywy: sudo apt install kubectx (starsza wersja) albo kubectl krew install ctx ns
VER=v0.11.0
for t in kubectx kubens; do
  curl -fsSLo /tmp/$t.tgz https://github.com/ahmetb/kubectx/releases/download/$VER/${t}_${VER}_linux_x86_64.tar.gz
  tar -xzf /tmp/$t.tgz -C /tmp $t && sudo install /tmp/$t /usr/local/bin/$t
done
kubectx --version

# C. kubectx – przełączanie klastrów
kubectx                                      # lista, bieżący podświetlony
kubectx kind-lab-klaster
kubectx -                                    # powrót do poprzedniego (jak cd -)
kubectx -c                                   # bieżący kontekst

# D. kubens – przełączanie namespace'ów w bieżącym kontekście
kubens                                       # lista namespace'ów klastra
kubens kube-system
kubectl get pods                             # bez -n
kubens -                                     # powrót do poprzedniego
kubens default
