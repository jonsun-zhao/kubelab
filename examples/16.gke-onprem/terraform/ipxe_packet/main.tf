provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

provider "external" {
  version = "~> 1.0"
}

# fetch OS id from packet
data "packet_operating_system" "esxi" {
  name             = "Custom iPXE"
  distro           = "custom_ipxe"
  version          = "1"
  provisionable_on = "${var.packet_device_plan}"
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
  ipxe_script_url         = "${var.ipxe_script_url}"
}

# fetch gw ip and expose it via output
data "external" "esxi_gw_ip" {
  program    = ["bash", "${path.module}/files/fetch_gw_ip.sh", "${var.packet_auth_token}", "${packet_device.esxi.id}"]
  depends_on = ["packet_device.esxi"]
}
