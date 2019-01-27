#!/bin/sh

out="files/esxi_tmp.sh"

token=$1; shift
volume=$1; shift
user=$1; shift
pw=$1; shift

cat > $out <<EOF
#!/bin/sh

sleep 20

# setup esxi account and networking
esxcli network vswitch standard add -v external
esxcli network vswitch standard policy security set -f true -v external
esxcli network vswitch standard add -v internal
esxcli network vswitch standard policy security set -f true -v internal
esxcli network vswitch standard add -v management
esxcli network vswitch standard policy security set -f true -v management
esxcfg-vswitch external -A 'external vm network'
esxcfg-vswitch internal -A 'internal vm network'
esxcfg-vswitch management -A 'internal management'
esxcfg-vswitch management -A 'internal vmk management'
esxcfg-vmknic -a -i 172.16.10.3 -n 255.255.255.0 -p 'internal vmk management'
esxcli network ip interface tag add -i vmk2 -t Management
esxcli system account add -i ${user} -p ${pw} -c ${pw}
esxcli system permission set -i ${user} -r Admin
EOF

set -- `curl -s -X GET --header 'Accept: application/json' --header "X-Auth-Token: ${token}" https://api.packet.net/storage/${volume} | jq -r '.access| (.ips[]|.), (.iqn)'`

ip1=$1; shift
ip2=$1; shift
target=$1; shift

cat >> $out << 'EOF'

# setup storage
ls /dev/disks >disks1.txt
EOF

echo "esxcli iscsi adapter discovery statictarget add --address=${ip1}:3260 --adapter=vmhba64 --name=${target}" >> $out
echo "esxcli iscsi adapter discovery statictarget add --address=${ip2}:3260 --adapter=vmhba64 --name=${target}" >> $out

cat >> $out <<'EOF'
esxcli iscsi adapter discovery rediscover --adapter=vmhba64
esxcli storage core adapter rescan --adapter=vmhba64
ls /dev/disks >disks2.txt
DISK=$(diff disks1.txt disks2.txt | grep ^+naa|sed 's/^+//g')
LAST=$(($(partedUtil "getptbl" /vmfs/devices/disks/$DISK | grep ^[0-9] | cut -d' ' -f4)-50))
partedUtil "setptbl" "/vmfs/devices/disks/$DISK" "gpt" "1 2048 $LAST AA31E02A400F11DB9590000C2911D1B8 0"
vmkfstools -C vmfs6 -b 1m -S persistent_ds1 /vmfs/devices/disks/$DISK:1
EOF

chmod +x $out