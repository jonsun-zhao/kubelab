[nsvm]
${nsvm_public_ip}

[nsvm:vars]
ansible_connection=ssh
ansible_ssh_user=${nsvm_admin_username}
ansible_ssh_pass=${nsvm_admin_password}
ansible_password=${nsvm_admin_password}
ansible_sudo_pass=${nsvm_admin_password}
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
gkeonprem_service_account_key_file=${gkeonprem_service_account_key_file}
gkeonprem_service_account_email=${gkeonprem_service_account_email}
gcp_project=${gcp_project}
gcp_compute_zone=${gcp_compute_zone}

[all:vars]
vcenter_admin_username=${vcenter_username}
vcenter_admin_password=${vcenter_password}
esxi_gw_ip=${esxi_gw_ip}
esxi_public_ip=${esxi_public_ip}
esxi_username=${esxi_username}
esxi_password=${esxi_password}
esxi_hostname=${esxi_hostname}
esxi_ds_name=${esxi_ds_name}
nsvm_admin_username=${nsvm_admin_username}
nsvm_admin_password=${nsvm_admin_password}
f5_addr=${f5_addr}
f5_user=${f5_user}
f5_pass=${f5_pass}
f5_key=${f5_key}
govc_guest_login=${govc_guest_login}
ova_f5=${ova_f5}
govc=${govc}
buildscripts=${buildscripts}
vcenter_iso=${vcenter_iso}