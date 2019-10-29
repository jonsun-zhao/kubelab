output "esxi_public_ip" {
  value = "${packet_device.esxi.access_public_ipv4}"
}

output "esxi_networks" {
  value = "${packet_device.esxi.network}"
}

output "networks" {
  value = "${length(packet_device.esxi.network)}"
}

output "esxi_gw_ip" {
  value = "${data.external.esxi_gw_ip.result["ip"]}"
}
