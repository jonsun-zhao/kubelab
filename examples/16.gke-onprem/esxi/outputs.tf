output "volume_info" {
  value = "${packet_volume.datastore.state}"
}

output "esxi_host_public_ip" {
  value = "${packet_device.esxi.access_public_ipv4}+1"
}
