[vcenter]
${vcenter_public_ip}

[vcenter:vars]
ansible_connection=ssh
ansible_ssh_user=${admin_ws_admin_username}
ansible_ssh_pass=${admin_ws_admin_password}
ansible_password=${admin_ws_admin_password}
ansible_sudo_pass=${admin_ws_admin_password}
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'

[admin_ws]
${esxi_public_ip}

[admin_ws:vars]
ansible_connection=ssh
ansible_ssh_user=${esxi_username}
ansible_ssh_pass=${esxi_password}
ansible_password=${esxi_password}
ansible_sudo_pass=${esxi_password}
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'

[all:vars]
vcenter_public_ip=${vcenter_public_ip}
vcenter_admin_username=${vcenter_username}
vcenter_admin_password=${vcenter_password}
esxi_gw_ip=${esxi_gw_ip}
esxi_public_ip=${esxi_public_ip}
esxi_username=${esxi_username}
esxi_password=${esxi_password}
esxi_hostname=${esxi_hostname}
admin_ws_admin_username=${admin_ws_admin_username}
admin_ws_admin_password=${admin_ws_admin_password}
f5_addr=${f5_addr}
f5_user=${f5_user}
f5_pass=${f5_pass}
f5_key=${f5_key}
govc_guest_login=${govc_guest_login}
ova_admin_ws=${ova_admin_ws}
ova_vcsa=${ova_vcsa}
ova_f5=${ova_f5}
