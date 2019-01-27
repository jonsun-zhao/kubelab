provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

# fetch OS id from packet
data "packet_operating_system" "esxi" {
  name             = "VMware ESXi 6.5"
  distro           = "vmware"
  version          = "6.5"
  provisionable_on = "${var.packet_device_plan}"
}

# create packet volume
# packet_volume doesn't have a name argument :(
resource "packet_volume" "datastore" {
  description   = "vshpere data store"
  facility      = "sjc1"
  project_id    = "${var.packet_project_id}"
  plan          = "${var.packet_storage_plan}"
  size          = 500
  billing_cycle = "hourly"
}

# create packet device/machine
resource "packet_device" "esxi" {
  hostname         = "${var.esxi_hostname}"
  plan             = "${var.packet_device_plan}"
  facility         = "sjc1"
  operating_system = "${data.packet_operating_system.esxi.id}"
  billing_cycle    = "hourly"
  project_id       = "${var.packet_project_id}"

  # generate the bootstrap script
  provisioner "local-exec" {
    command = "${path.module}/files/esxi_gen.sh ${var.packet_auth_token} ${packet_volume.datastore.id} ${var.esxi_admin_username} ${var.esxi_admin_password}"
  }

  # generate the vapp property json for admin ws
  provisioner "local-exec" {
    command = "${path.module}/files/admin_ws_gen.sh ${var.packet_auth_token} ${packet_device.esxi.id}"
  }

  depends_on = ["packet_volume.datastore"]
}

# attach volume to the machine
resource "packet_volume_attachment" "attach_volume" {
  device_id = "${packet_device.esxi.id}"
  volume_id = "${packet_volume.datastore.id}"

  connection {
    host        = "${packet_device.esxi.access_public_ipv4}"
    type        = "ssh"
    user        = "root"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  # run bootstrap script on esxi
  provisioner "remote-exec" {
    script = "${path.module}/files/esxi_tmp.sh"
  }

  depends_on = ["packet_device.esxi"]
}

# import admin workstation to esxi
resource "null_resource" "import_admin_ws" {
  provisioner "local-exec" {
    command = "govc import.ova -options=${path.module}/files/admin_ws_tmp.json ${var.ova_admin_ws}"

    # command = "echo $GOVC_URL; echo $GOVC_PASSWORD"
    environment {
      GOVC_INSECURE      = 1
      GOVC_URL           = "${packet_device.esxi.access_public_ipv4}"
      GOVC_USERNAME      = "${var.esxi_admin_username}"
      GOVC_PASSWORD      = "${var.esxi_admin_password}"
      GOVC_DATASTORE     = "persistent_ds1"
      GOVC_RESOURCE_POOL = "*/Resources"
    }
  }

  depends_on = ["packet_volume_attachment.attach_volume"]
}
