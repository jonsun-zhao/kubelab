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

# build esxi bootstrap script from template
data "template_file" "esxi_sh" {
  template = "${file("${path.module}/files/esxi_sh.tpl")}"

  vars = {
    user = "${var.esxi_admin_username}"
    pw   = "${var.esxi_admin_password}"
  }
}

# fetch gw ip and expose it via output
data "external" "esxi_gw_ip" {
  program    = ["bash", "${path.module}/files/fetch_gw_ip.sh", "${var.packet_auth_token}", "${packet_device.esxi.id}"]
  depends_on = ["local_file.esxi_sh"]
}

# deploy esxi host
resource "packet_device" "esxi" {
  hostname                = "${var.esxi_hostname}"
  plan                    = "${var.packet_device_plan}"
  facilities              = ["${var.packet_region}"]
  operating_system        = "${data.packet_operating_system.esxi.id}"
  billing_cycle           = "hourly"
  project_id              = "${var.packet_project_id}"
  public_ipv4_subnet_size = "29"
}

# create and execute the esxi bootstrap script
resource "local_file" "esxi_sh" {
  content  = "${data.template_file.esxi_sh.rendered}"
  filename = "${path.module}/files/esxi_tmp.sh"

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

### THIS CAN BE UNCOMMMENTED ONCE TERRAFORM 0.12 IS RELEASED #####
//data "template_file" "packet_gw_public" {
//  count    = "${length(packet_device.esxi.network)}"
//  template = "${lookup(packet_device.esxi.network[count.index], "public") == 1 && lookup(packet_device.esxi.network[count.index], "family") == "4" ? lookup(packet_device.esxi.network[count.index], "gateway") : "" }"
//  depends_on = ["packet_device.esxi"]
//}

