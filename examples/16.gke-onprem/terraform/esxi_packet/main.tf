provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

provider "external" {
  version = "~> 1.0"
}

# fetch OS id from packet
data "packet_operating_system" "esxi" {
  name             = "VMware ESXi 6.5"
  distro           = "vmware"
  version          = "6.5"
  provisionable_on = "${var.packet_device_plan}"
}

# create the datastore volume
# packet_volume doesn't have a name argument :(
resource "packet_volume" "datastore" {
  description   = "vshpere data store"
<<<<<<< HEAD
  facility      = "${var.packet_region}"
=======
  facility      = "${var.packet_facility}"
>>>>>>> guest_run
  project_id    = "${var.packet_project_id}"
  plan          = "${var.packet_storage_plan}"
  size          = 1000
  billing_cycle = "hourly"
}

# deploy esxi host
resource "packet_device" "esxi" {
<<<<<<< HEAD
  hostname                = "${var.esxi_hostname}"
  plan                    = "${var.packet_device_plan}"
  facility                = "${var.packet_region}"
  operating_system        = "${data.packet_operating_system.esxi.id}"
  billing_cycle           = "hourly"
  project_id              = "${var.packet_project_id}"
  public_ipv4_subnet_size = "29"
=======
  hostname         = "${var.esxi_hostname}"
  plan             = "${var.packet_device_plan}"
  facility         = "${var.packet_facility}"
  operating_system = "${data.packet_operating_system.esxi.id}"
  billing_cycle    = "hourly"
  project_id       = "${var.packet_project_id}"
>>>>>>> guest_run

  depends_on = ["packet_volume.datastore"]
}

data "external" "volume_info" {
  program    = ["bash", "${path.module}/files/fetch_vol_info.sh", "${var.packet_auth_token}", "${packet_volume.datastore.id}"]
  depends_on = ["packet_volume.datastore"]
}

data "template_file" "esxi_sh" {
  template = "${file("${path.module}/files/esxi_sh.tpl")}"

  vars = {
    token  = "${var.packet_auth_token}"
    volume = "${packet_volume.datastore.id}"
    user   = "${var.esxi_admin_username}"
    pw     = "${var.esxi_admin_password}"
    ds     = "${var.esxi_ds_name}"
    ip1    = "${data.external.volume_info.result["ip1"]}"
    ip2    = "${data.external.volume_info.result["ip2"]}"
    target = "${data.external.volume_info.result["target"]}"
  }

  depends_on = ["data.external.volume_info"]
}

# build the esxi bootstrap script from template
resource "local_file" "esxi_sh" {
  content  = "${data.template_file.esxi_sh.rendered}"
  filename = "${path.module}/files/esxi_tmp.sh"

  depends_on = ["packet_device.esxi"]
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

  depends_on = ["packet_device.esxi", "local_file.esxi_sh"]
}

# fetch gw ip and expose it via output
data "external" "esxi_gw_ip" {
  program    = ["bash", "${path.module}/files/fetch_gw_ip.sh", "${var.packet_auth_token}", "${packet_device.esxi.id}"]
  depends_on = ["packet_volume_attachment.attach_volume"]
}

### THIS CAN BE UNCOMMMENTED ONCE TERRAFORM 0.12 IS RELEASED #####
//data "template_file" "packet_gw_public" {
//  count    = "${length(packet_device.esxi.network)}"
//  template = "${lookup(packet_device.esxi.network[count.index], "public") == 1 && lookup(packet_device.esxi.network[count.index], "family") == "4" ? lookup(packet_device.esxi.network[count.index], "gateway") : "" }"
//  depends_on = ["packet_device.esxi"]
//}

