output "esxi_public_ip" {
  value = "${packet_device.esxi.access_public_ipv4}"
}

output "esxi_networks" {
  value = "${packet_device.esxi.network}"
}

//#### ASSUMPTION IS THAT THE PUBLIC IPv4 IS ALWAYS IN POSITION 0 IN THE LIST ####
//output "esxi_gw_ip" {
//  value = "${lookup(packet_device.esxi.network[0], "gateway")}"
//}

output "networks" {
  value = "${length(packet_device.esxi.network)}"
}


output "esxi_gw_ip" {
  value = "${data.external.esxi_gw_ip.result["ip"]}"
}