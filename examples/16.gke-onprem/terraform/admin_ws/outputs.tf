output "admin_ws_public_ip" {
  value = "${data.external.admin_ws_public_ip.result["ip"]}"
}
