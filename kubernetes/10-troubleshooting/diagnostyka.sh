#!/usr/bin/env bash
# 10. Troubleshooting – diagnostyka klastra. Podmień <...> na własne wartości.

# 10.1 Pod utknął w stanie Pending / CrashLoopBackOff
# Zepsuty Pod do ćwiczeń (kończy się błędem → CrashLoopBackOff):
kubectl run crash-test --image=busybox:1.37 -- sh -c 'echo start; exit 1'
sleep 20
kubectl get pod crash-test          # STATUS: CrashLoopBackOff, RESTARTS rośnie (przerwy 10 s, 20 s, 40 s… do 5 min)
kubectl describe pod crash-test     # sekcja Events = przyczyna; Last State: Terminated, Exit Code: 1
kubectl logs crash-test --previous  # logi poprzedniego cyklu
kubectl get events --sort-by=.lastTimestamp
kubectl delete pod crash-test

# 10.2 Węzeł NotReady
kubectl describe node minikube | sed -n '/Conditions/,/Addresses/p'   # MemoryPressure, DiskPressure, PIDPressure, Ready
# Na węźle (kubeadm z sekcji 7: ssh na węzeł; minikube: minikube ssh):
#   systemctl status kubelet           # sprawdź czy kubelet działa na węźle
#   journalctl -u kubelet -f           # logi kubeleta w czasie rzeczywistym
minikube ssh -- sudo journalctl -u kubelet --no-pager | tail -5

# 10.3 Problemy z połączeniem sieciowym – Pod diagnostyczny z narzędziami sieciowymi
# kubectl run netdebug --image=nicolaka/netshoot:v0.15 --rm -it -- bash
#   nslookup frontend-svc             # test DNS Service (Serwisy z ćwiczenia 4.3)
#   curl -v http://backend-svc        # test HTTP Service (materiały: port 8080 – backend z 4.3 słucha na 80)
#   traceroute 10.96.0.1              # trace do ClusterIP Serwisu kubernetes
kubectl run netdebug --image=nicolaka/netshoot:v0.15 --rm -i --restart=Never -- \
  sh -c 'nslookup kubernetes.default.svc.cluster.local; curl -sk https://kubernetes.default.svc.cluster.local/version | head -4'   # "recursion not available" to szum, ważny jest adres 10.96.0.1
# Serwis nie odpowiada? Najpierw sprawdź, czy ma adresy Podów:
kubectl get endpointslices -A | grep '<unset>'   # Serwisy bez żadnego gotowego Poda

# 10.4 Szybkie polecenia diagnostyczne
kubectl get pods -A --field-selector=status.phase!=Running   # wszystkie nie-Running (także Completed Joby)
kubectl top nodes                                            # CPU/RAM węzłów (Metrics Server)
kubectl top pods -A --sort-by=memory                         # najcięższe Pody
kubectl get componentstatuses                                # przestarzałe (Warning) – zamiast tego:
kubectl get --raw='/readyz?verbose'                          # stan API Servera i etcd
kubectl cluster-info dump --output-directory=/tmp/k8s-dump   # pełny dump diagnostyczny
