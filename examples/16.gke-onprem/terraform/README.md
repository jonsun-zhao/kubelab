# Build the Lab on Packet.com

## Prerequisites

* Install [govc](https://github.com/vmware/govmomi/tree/master/govc)
* Install [jq](https://stedolan.github.io/jq/download/)
* Request a [packet.com](https://www.packet.com) account
* Make sure your **SSH key-pair** are located in `~/.ssh` and named as follow
  * `id_rsa`
  * `id_rsa.pub`
* Create a **SSH key**, with the content of your `id_rsa.pub`, in your `packet.com` profile
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

### Prepare Terraform variables

* Create the `terraform.tfvars` file (example)

  * **Please use the `ova_admin_ws` in the example as it is**
  * The admin workstation OVA in `nmiu-play_tools` bucket is modified to accept a vApp property which is required for this terraform script
  * Passwords can be found in the Lab doc

  ```sh
  packet_auth_token = "YOUR_PACKET_ACCOUNT_AUTH_TOKEN"

  packet_project_id = "YOUR_PACKET_PROJET"

  packet_device_plan = "c2.medium.x86"

  packet_facility = "sjc1"

  packet_storage_plan = "storage_2"

  esxi_hostname = "YOUR_ESXI_HOSTNAME"

  esxi_admin_username = "gkeadmin"

  esxi_admin_password = "YOUR_ESXI_ADMIN_PASSWORD"

  vcenter_admin_username = "administrator@gkeonprem.local"

  vcenter_admin_password = "YOUR_VCENTER_ADMIN_PASSWORD"

  admin_ws_admin_username = "gkeadmin"

  admin_ws_admin_password = "YOUR_ADMIN_WS_ADMIN_PASSWORD"

  ova_admin_ws = "http://storage.googleapis.com/nmiu-play_tools/admin-ws-20190308.ova"

  ova_vcsa = "https://storage.googleapis.com/gke-on-prem-lab-ovas/current/vcsa-latest.ova"

  ova_f5 = "https://storage.googleapis.com/gke-on-prem-lab-ovas/current/f5-latest.ova"
  ```

### Run Terraform

```sh
terraform init
terraform plan
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

### Run Terraform

```sh
terraform destroy
```
