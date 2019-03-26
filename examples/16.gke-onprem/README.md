# Build the Packet Lab with Terraform

## TO DO LIST AND GOTCHA'S!
* You still need to `shut down` the `Admin WS` and `enable cpu performance counter` for the gke install to work. I haven't figured out how to do this with govc but it seems possible as you can in terraform's VMware resources which uses [govmoni library](https://github.com/terraform-providers/terraform-provider-vsphere/search?q=cpu_performance_counters_enabled&unscoped_q=cpu_performance_counters_enabled)
* Need to breakout the `main.yml` ansible file into modules to make it easier to manage
* Build a tear down module in ansible to tear down the install and then reinstall the VMs
* Once the above is done, then we can work to automate the gke-onprem install too then.

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


### Prepare Terraform variables (`terraform.tfvar`)

```sh
cp terraform.tfvars.template terraform.tfvars
```

* Make necessary changes to the `terraform.tfvars`

  ```sh
  packet_project_id = ""

  packet_device_plan = "c2.medium.x86"

  packet_storage_plan = "storage_2"

  esxi_hostname = "YOUR_ESXI_HOSTNAME"

  esxi_admin_username = "gkeadmin"

  esxi_admin_password = "YOUR_ESXI_ADMIN_PASSWORD"

  vcenter_admin_username = "administrator@gkeonprem.local"

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
terraform plan
terraform apply
```

### Run Ansible after terraform succesfully provision packet environment to setup the Admin Workstation, vCenter Appliance, and the F5 BIG-IP Appliance
```sh
cd admin_ws_ansible/file
ansible-playbook main.yaml -i inventory.yaml
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
