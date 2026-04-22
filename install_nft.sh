#!/bin/bash

# Запускать от root: sudo bash install_nft.sh

TARGET_IP="XXX.XXX.XXX.XXX" # IP удаленного сервера куда перенаправляем трафик (нужно изменить)
TARGET_PORT="XXXXX"          # порт на котором слушает удаленный сервер (можно изменить)
IN_PORT="XXXXX"              # порт на котором слушает ЭТОТ сервер (можно изменить)
PROTO="udp"                  # udp для WireGuard/AmneziaWG, tcp для VLESS

# Определяем сетевой интерфейс
IFACE=$(ip route get 8.8.8.8 | awk '{print $5}')

# Включаем IP Forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Устанавливаем nftables
apt-get install -y nftables -q
systemctl enable nftables

# Пишем конфиг
cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f

flush ruleset

table ip nat {
    chain prerouting {
        type nat hook prerouting priority -100;
        ip protocol $PROTO $PROTO dport $IN_PORT dnat to $TARGET_IP:$TARGET_PORT
    }
    chain postrouting {
        type nat hook postrouting priority 100;
        oifname "$IFACE" masquerade
    }
}

table ip filter {
    chain input {
        type filter hook input priority 0;
        ip protocol $PROTO $PROTO dport $IN_PORT accept
    }
    chain forward {
        type filter hook forward priority 0;
        ip protocol $PROTO ip daddr $TARGET_IP $PROTO dport $TARGET_PORT ct state new,established,related accept
        ip protocol $PROTO ip saddr $TARGET_IP $PROTO sport $TARGET_PORT ct state established,related accept
    }
}
EOF

# Применяем
nft -f /etc/nftables.conf

echo "Готово! Трафик :$IN_PORT -> $TARGET_IP:$TARGET_PORT ($PROTO)"
