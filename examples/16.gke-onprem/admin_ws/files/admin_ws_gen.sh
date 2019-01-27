#!/bin/bash

out='files/admin_ws_tmp.sh'

esxi_host=172.16.10.3
vcenter_admin_username=$1; shift
vcenter_admin_password=$1; shift
esxi_admin_username=$1; shift
esxi_admin_password=$1; shift

cat > $out << EOF
#!/bin/bash

[ -x "/tmp/govc" ] || chmod +x /tmp/govc

export GOVC_INSECURE=true
export GOVC_DATACENTER='GKE On-Prem'
export GOVC_URL='https://${vcenter_admin_username}:${vcenter_admin_password}@vcenter/sdk'

/tmp/govc cluster.add -cluster 'GKE On-Prem' \
-hostname '${esxi_host}' \
-username '${esxi_admin_username}' \
-password '${esxi_admin_password}' \
-noverify
EOF

chmod +x $out