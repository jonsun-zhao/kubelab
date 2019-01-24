provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

# fetch OS id from packet
data "packet_operating_system" "esxi" {
  name             = "VMware ESXi 6.5"
  distro           = "vmware"
  version          = "6.5"
  provisionable_on = "${var.packet_plan_name}"
}

# create packet volume
# packet_volume doesn't have a name argument :(
resource "packet_volume" "datastore" {
  description   = "vshpere data store"
  facility      = "sjc1"
  project_id    = "${var.packet_project_id}"
  plan          = "storage_1"
  size          = 1000
  billing_cycle = "hourly"
}

# create packet device/machine
resource "packet_device" "esxi" {
  hostname         = "${var.esxi_hostname}"
  plan             = "baremetal_0"
  facility         = "sjc1"
  operating_system = "${data.packet_operating_system.esxi.id}"
  billing_cycle    = "hourly"
  project_id       = "${var.packet_project_id}"

  # generate the bootstrap script
  provisioner "local-exec" {
    command = "${path.module}/files/gen_esxi_mod.sh ${var.packet_auth_token} ${packet_volume.datastore.id} ${var.esxi_admin_username} ${var.esxi_admin_password}"
  }

  # copy the bootstrap script onto esxi
  provisioner "file" {
    connection {
      type     = "ssh"
      user     = "root"
      private_key = "${file("~/.ssh/id_rsa")}"
    }

    source      = "${path.module}/files/esxi_mod.sh"
    destination = "/esxi_mod.sh"
  }

  depends_on = [ "packet_volume.datastore" ]
}

# attach volume to the machine
resource "packet_volume_attachment" "attach_volume" {
  device_id = "${packet_device.esxi.id}"
  volume_id = "${packet_volume.datastore.id}"

  connection {
    host = "${packet_device.esxi.access_public_ipv4}"
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      private_key = "${file("~/.ssh/id_rsa")}"
    }

    # run bootstrap script on esxi
    inline = [
      "chmod +x /esxi_mod.sh",
      "sleep 10",
      "/esxi_mod.sh",
    ]
  }

  depends_on = [ "packet_device.esxi" ]
}

# import OVAs to esxi
resource "null_resource" "import-ovas" {

  provisioner "local-exec" {
    command = <<EOF
govc import.ova -options=${path.module}/files/adminws.json http://storage.googleapis.com/nmiu-play_tools/adminws-9.ova;
govc import.ova -options=${path.module}/files/vcsa.json http://storage.googleapis.com/nmiu-play_tools/vcsa-2.ova;
govc import.ova -options=${path.module}/files/f5.json http://storage.googleapis.com/nmiu-play_tools/f5-3.ova;
EOF

    # command = "echo $GOVC_URL; echo $GOVC_PASSWORD"
    environment {
      GOVC_INSECURE = 1
      GOVC_URL = "${packet_device.esxi.access_public_ipv4}"
      GOVC_USERNAME = "${var.esxi_admin_username}"
      GOVC_PASSWORD = "${var.esxi_admin_password}"
      GOVC_DATASTORE = "persistent_ds1"
      GOVC_RESOURCE_POOL = "*/Resources"
    }
  }

  depends_on = [ "packet_volume_attachment.attach_volume" ]
}
