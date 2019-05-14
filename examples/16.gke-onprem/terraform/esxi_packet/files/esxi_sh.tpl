#!/bin/sh

sleep 20

# fetch packet metadaata
wget http://metadata.packet.net/metadata -O /tmp/metadata
uuid=$(cat /tmp/metadata | python -c "import sys, json; print(json.load(sys.stdin)['id'])")
hostname=$(cat /tmp/metadata | python -c "import sys, json; print(json.load(sys.stdin)['hostname'])")

# set hostname
esxcli system hostname set --fqdn=$hostname

sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config

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

# setup storage

# the head disk used by esxi always has a :3 partition
head_disk=$(ls /dev/disks/ | grep ^naa | grep ':3' | awk -F':' '{print $1}' | uniq)

# loop through the rest of the disks
for d in $(ls /dev/disks/ | grep ^naa | grep -v "$head_disk" | grep -v ':' | uniq); do
  # skip the disk that already has a vmfs partition
  if $(partedUtil "getptbl" /vmfs/devices/disks/$d | grep -q vmfs); then
    continue
  fi
  echo $d
  # get the last sector of the disk
  last=$(($(partedUtil "getptbl" /vmfs/devices/disks/$d | grep ^[0-9] | cut -d' ' -f4) - 50))
  # create a partition that consumes the entire disk
  partedUtil "setptbl" "/vmfs/devices/disks/$d" "gpt" "1 2048 $last aA31E02A400F11DB9590000C2911D1B8 0"
  # extend vmfs with $d:1
  echo 0 | vmkfstools -Z /vmfs/devices/disks/$d:1 /vmfs/devices/disks/$head_disk:3
done

# wait for vmfs extention to finish
sleep 60

# download images from network
mkdir /vmfs/volumes/datastore1/Downloads
wget -P /vmfs/volumes/datastore1/Downloads http://iso.packet.cloud/ubuntu-18.04.2-live-server-amd64.iso

# import nsvm
nsvm=/vmfs/volumes/datastore1/netservices-base
mkdir $nsvm
wget -qO- http://storage.googleapis.com/gke-on-prem-lab-ovas/current/netservicesvm-latest.tar.gz | tar zxf - -C $nsvm
vim-cmd solo/registervm $nsvm/netservicesvm-3.vmx
