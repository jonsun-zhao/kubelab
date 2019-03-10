#!/bin/bash

GATEWAY=$1

LAST=$(echo $GATEWAY | cut -d . -f 4)

FIRST=$(echo $GATEWAY | cut -d . -f 1-3)

ADMIN=$((LAST + 2))
IP1=$((LAST + 3))
IP2=$((LAST + 4))
IP3=$((LAST + 5))

cp /opt/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
sed -i -e "s/x.x.x.x/$FIRST.$ADMIN/g" /etc/netplan/50-cloud-init.yaml
sed -i -e "s/x1.x1.x1.x1/$FIRST.$IP1/g" /etc/netplan/50-cloud-init.yaml
sed -i -e "s/x2.x2.x2.x2/$FIRST.$IP2/g" /etc/netplan/50-cloud-init.yaml
sed -i -e "s/x3.x3.x3.x3/$FIRST.$IP3/g" /etc/netplan/50-cloud-init.yaml
sed -i -e "s/y.y.y.y/$GATEWAY/g" /etc/netplan/50-cloud-init.yaml
netplan apply

iptables -t nat -A POSTROUTING -o ens160 -s 10.0.10.251 -j SNAT --to-source $FIRST.$IP1
iptables -t nat -A PREROUTING -i ens160 -d $FIRST.$IP1 -j DNAT --to-destination 10.0.10.251
iptables -A FORWARD -s $FIRST.$IP1 -j ACCEPT
iptables -A FORWARD -d 10.0.10.251 -j ACCEPT

iptables -t nat -A POSTROUTING -o ens160 -s 10.0.10.252 -j SNAT --to-source $FIRST.$IP2
iptables -t nat -A PREROUTING -i ens160 -d $FIRST.$IP2 -j DNAT --to-destination 10.0.10.252
iptables -A FORWARD -s $FIRST.$IP2 -j ACCEPT
iptables -A FORWARD -d 10.0.10.252 -j ACCEPT

iptables -t nat -A POSTROUTING -o ens160 -s 10.0.10.253 -j SNAT --to-source $FIRST.$IP3
iptables -t nat -A PREROUTING -i ens160 -d $FIRST.$IP3 -j DNAT --to-destination 10.0.10.253
iptables -A FORWARD -s $FIRST.$IP3 -j ACCEPT
iptables -A FORWARD -d 10.0.10.253 -j ACCEPT

iptables-save > /etc/iptables/rules.v4

sleep 10
ping www.google.com -c 5

systemctl restart isc-dhcp-server
