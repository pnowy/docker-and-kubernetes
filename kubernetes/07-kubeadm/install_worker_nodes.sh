#!/usr/bin/env bash
# Krok 2: przygotowanie Worker Node – uruchom na każdej maszynie worker
set -euo pipefail
cd "$(dirname "$0")" || exit 1

./common.sh

printf '\n\033[1;32mWorker %s przygotowany.\033[0m Teraz wykonaj polecenie z pliku info_join_worker (z mastera), np.:\n' "$(hostname)"
echo "  sudo kubeadm join <IP_MASTER>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>"
