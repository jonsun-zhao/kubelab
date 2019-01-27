resource "null_resource" "esxi" {
  provisioner "local-exec" "create_esxi" {
    commmand = <<EOF
echo ${var.local_pw} | sudo -S virt-install \
--name=${var.esxi_vm_name} \
--cpu=host-passthrough \
--ram ${var.esxi_vm_memory_size} --vcpus=${var.esxi_vm_cores} \
--os-type linux \
--os-variant=virtio26 \
--virt-type=kvm --hvm \
--cdrom ${var.esxi_vm_iso} \
--network network:default,model=e1000 \
--graphics vnc --video qxl \
--disk pool=default,size=${var.esxi_vm_storage_size},sparse=true,bus=sata,format=qcow2 \
--machine q35 \
--boot cdrom,hd --noautoconsole --force
EOF
  }

  provisioner "local-exec" "delete_esxi" {
    when = "destroy"

    command = <<EOF
echo ${var.local_pw} | sudo -S su -c '\
virsh destory ${var.esxi_vm_name}; \
virsh undefine ${var.esxi_vm_name}; \
virsh vol-delete --pool default ${var.esxi_vm_name}.qcow2 \
'
EOF
  }
}
