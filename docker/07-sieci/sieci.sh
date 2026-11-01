#!/usr/bin/env bash
# Sekcja 7 – Sieci w Dockerze

# --- Zarządzanie sieciami ---
docker network ls                                             # bridge, host, none – sieci tworzone przy instalacji
docker network create moja-siec-aplikacji
docker network inspect moja-siec-aplikacji                    # podsieć, brama, podłączone kontenery

# --- Kontenery we wspólnej sieci użytkownika komunikują się po nazwach ---
docker run -d --name moj-backend  --network moja-siec-aplikacji httpd:2.4
docker run -d --name moj-frontend --network moja-siec-aplikacji -p 8080:80 nginx:1.29
docker exec moj-frontend curl -s http://moj-backend/          # nazwa kontenera = nazwa DNS
docker exec moj-frontend cat /etc/resolv.conf                 # nameserver 127.0.0.11 – wbudowany DNS Dockera
docker run --rm --network moja-siec-aplikacji busybox:1.37 nslookup moj-backend.
# Kropka na końcu = bez domen "search" hosta (np. *.cloudapp.net na VM w Azure) – inaczej BusyBox dopisuje NXDOMAIN obok poprawnego adresu

# --- Aliasy sieciowe – kilka kontenerów pod jedną nazwą ---
docker run -d --name api1 --network moja-siec-aplikacji --network-alias api httpd:2.4
docker run -d --name api2 --network moja-siec-aplikacji --network-alias api httpd:2.4
docker run --rm --network moja-siec-aplikacji busybox:1.37 nslookup api.   # dwa adresy IP

# --- Domyślna sieć bridge NIE ma DNS po nazwach ---
docker run -d --name stary1 busybox:1.37 sleep 300
docker run --rm busybox:1.37 ping -c1 -W1 stary1 || echo "Brak DNS w domyślnej sieci bridge"

# --- Publikowanie portów ---
docker port moj-frontend                                      # 80/tcp -> 0.0.0.0:8080
docker run -d --name tylko-lokalnie -p 127.0.0.1:8081:80 nginx:1.29   # port dostępny tylko z hosta
docker run -d --name losowy-port -P nginx:1.29                # -P: losowe porty hosta dla wszystkich EXPOSE
docker port losowy-port

# --- Podłączanie i odłączanie kontenera ---
docker network connect moja-siec-aplikacji stary1
docker exec stary1 ping -c1 moj-backend                       # teraz działa
docker inspect -f '{{json .NetworkSettings.Networks}}' stary1 # kontener w dwóch sieciach
docker network disconnect moja-siec-aplikacji stary1

# --- Sterowniki host i none ---
docker run --rm --network none busybox:1.37 ip addr           # tylko interfejs lo
# docker run --rm --network host nginx:1.29                   # sieć hosta – w pełni tylko na Linuksie

# --- Sprzątanie ---
docker rm -f moj-backend moj-frontend api1 api2 stary1 tylko-lokalnie losowy-port
docker network rm moja-siec-aplikacji
docker network prune -f
