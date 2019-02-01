#!/bin/bash

GOVC_CMD='/tmp/govc'

[ -x $GOVC_CMD ] || chmod +x $GOVC_CMD

export GOVC_USERNAME='${esxi_admin_username}'
export GOVC_PASSWORD='${esxi_admin_password}'

# import vcenter
$GOVC_CMD import.ova \
  -k \
  -u=${esxi_host} \
  -ds='persistent_ds1' \
  -pool='*/Resources' \
  -options=/tmp/vcsa.json \
  ${ova_vcsa}

# import f5
$GOVC_CMD import.ova \
  -k \
  -u=${esxi_host} \
  -ds='persistent_ds1' \
  -pool='*/Resources' \
  -options=/tmp/f5.json \
  ${ova_f5}

code=''
timeout=900

# check if vcenter api is alive (timeout in 10 minutes)
while [ "$code" != "200" ]; do
  if [ "$timeout" -le 0 ]; then
    echo 'Timed out trying to reach vcenter web interface'
    exit 1
  fi

  code=$(curl -s -o /dev/null -w "%%{http_code}" -k 'https://vcenter/vsphere-client/?csp')

  timeout=$((timeout - 10))
  sleep 10
done

# add esxi host to vcenter
export GOVC_USERNAME='${vcenter_admin_username}'
export GOVC_PASSWORD='${vcenter_admin_password}'

$GOVC_CMD cluster.add \
  -k \
  -u='https://vcenter/sdk' \
  -dc='GKE On-Prem' \
  -cluster='GKE On-Prem' \
  -hostname='${esxi_host}' \
  -username='${esxi_admin_username}' \
  -password='${esxi_admin_password}' \
  -noverify
