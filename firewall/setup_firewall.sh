#!/bin/sh

echo 1 > /proc/sys/net/ipv4/ip_forward

# --- POLÍTICA PADRÃO: BLOQUEAR TUDO (Default Deny) ---
echo "Aplicando política padrão: DROP"
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# --- LIMPEZA DE REGRAS ANTIGAS ---
echo "Limpando regras antigas..."
iptables -F
iptables -X

# --- REGRAS DE LIBERAÇÃO (ACCEPT) ---
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# --- REGRAS DE FORWARDING (Encaminhamento entre redes) ---
echo "Permitindo CLIENTE -> WEB (HTTP/S)"
iptables -A FORWARD -s 172.20.0.10 -d 172.21.0.10 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 172.20.0.10 -d 172.21.0.10 -p tcp --dport 443 -j ACCEPT
echo "Permitindo WEB -> DB (PostgreSQL)"
iptables -A FORWARD -s 172.21.0.10 -d 172.22.0.10 -p tcp --dport 5432 -j ACCEPT
echo "Permitindo CLIENTE -> WEB (PING)"
iptables -A FORWARD -s 172.20.0.10 -d 172.21.0.10 -p icmp --icmp-type echo-request -j ACCEPT


# --- REGRAS DE LOG (VISUALIZAÇÃO) ---
echo "Configurando logs para pacotes bloqueados"
iptables -A FORWARD -j LOG --log-prefix "[FW-BLOCKED-FORWARD] "

echo "Configuração do Firewall concluída."

# Para ver as regras aplicadas:
# iptables -L -v -n

# Para ver os logs (em outro terminal, no host):
# docker logs -f firewall-demo-firewall-1
