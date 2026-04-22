#!/bin/bash

# Запускать от root: sudo bash install.sh

TARGET_IP="XXX.XXX.XXX.XXX" # IP удаленного сервера куда перенаправляем траффик (нужно изменить)
TARGET_PORT="XXXXX"    # порт на котором слушает удаленный сервер (можно изменить)
IN_PORT="XXXXX"        # порт на котором слушает ЭТОТ сервер (можно изменить)
PROTO="udp"            # udp для WireGuard/AmneziaWG, tcp для VLESS

# Определяем сетевой интерфейс
IFACE=$(ip route get 8.8.8.8 | awk '{print $5}')

# Включаем IP Forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Применяем правила
iptables -A INPUT -p $PROTO --dport $IN_PORT -j ACCEPT
iptables -t nat -A PREROUTING -p $PROTO --dport $IN_PORT -j DNAT --to-destination $TARGET_IP:$TARGET_PORT
iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
iptables -A FORWARD -p $PROTO -d $TARGET_IP --dport $TARGET_PORT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p $PROTO -s $TARGET_IP --sport $TARGET_PORT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Сохраняем правила
apt-get install -y iptables-persistent -q
netfilter-persistent save

echo "Готово! Трафик :$IN_PORT -> $TARGET_IP:$TARGET_PORT ($PROTO)"
