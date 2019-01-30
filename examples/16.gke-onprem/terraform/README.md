# GKE-OP Lab

## Prerequisites

* Install [govc](https://github.com/vmware/govmomi/tree/master/govc)
* Install [jq](https://stedolan.github.io/jq/download/)
* Request an admin account in [packet.com](https://www.packet.com)
* Place your **SSH key-pair** in `~/.ssh` and name them
  * `id_rsa`
  * `id_rsa.pub`
* Add the content of your `id_rsa.pub` to your `packet.com` profile
* Create a **API Key** in your `packet.com` profile

## Deployment

### Terraform modifications

> Annoyingly the `packet_volume` resource doesn't support `name` argument, thus you have to change the existing `packet_volume` name to something unique

```sh
# Linux
sed -i "s/datastore/YOUR_VOLUME_NAME/g" *.tf

# Mac
sed -i '' "s/datastore/YOUR_VOLUME_NAME/g" *.tf
```

### Prepare Terraform variables (`terraform.tfvar`)

```sh
cp terraform.tfvars.template terraform.tfvars
```

* Make necessary changes to the `terraform.tfvars` (*i.e.*)

  ```sh
  packet_project_id = "231a57e1-a348-43ce-9b26-b1238e82dc4c"

  packet_device_plan = "c2.medium.x86"

  packet_storage_plan = "storage_2"

  esxi_hostname = "YOUR_ESXI_HOSTNAME"

  esxi_admin_username = "gkeadmin"

  esxi_admin_password = "YOUR_ESXI_ADMIN_PASSWORD"

  vcenter_admin_useranme = "administrator@gkeonprem.local"

  vcenter_admin_password = "YOUR_VCENTER_ADMIN_PASSWORD"

  admin_ws_admin_username = "gkeadmin"

  admin_ws_admin_password = "YOUR_ADMIN_WS_ADMIN_PASSWORD"

  ova_admin_ws = "http://storage.googleapis.com/nmiu-play_tools/admin-ws-1.ova"

  ova_vcsa = "http://storage.googleapis.com/nmiu-play_tools/vcsa-2.ova"

  ova_f5 = "http://storage.googleapis.com/nmiu-play_tools/f5-3.ova"
  ```

### Terraform apply

```sh
terraform init
terraform apply
```

## Tear down

### Shutdown `esxi` host from `packet.com`

> If you don't shut the `esxi` host down, `terraform destroy` will complain about not be able to unattach the volume from the host (below)

```sh
Error: Error applying plan:

1 error(s) occurred:

* module.esxi_packet.packet_volume_attachment.attach_volume (destroy): 1 error(s) occurred:

* packet_volume_attachment.attach_volume: DELETE https://api.packet.net/storage/attachments/bfc274e8-8668-4b6b-94cf-7931f204a3bd: 422 Cannot detach since volume is actively being used on your server
```

### Terraform destroy

```sh
terraform destroy
```
