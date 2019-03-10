# Build the Lab on Local machine (KVM)

## Prerequisites

* Configured nested virtualization on the machine
* Install [govc](https://github.com/vmware/govmomi/tree/master/govc)
* Install [jq](https://stedolan.github.io/jq/download/)

## Deploy

### Install ESXi

* cd into `esxi_kvm` directory

* Create the `terraform.tfvars` file

  ```sh
  esxi_vm_name = "esxi-local"

  esxi_vm_cores = "4"

  esxi_vm_memory_size = "32768"

  esxi_vm_storage_size = "300"

  esxi_vm_iso = "http://storage.googleapis.com/nmiu-play_tools/custom_esxi.iso"
  ```

* Run terraform

  ```sh
  terraform init
  terraform plan
  terraform apply
  ```

* Start the ESXi VM after installation

  > ESXi turn itself off when the installation is done, one need to boot it back up manually via `virsh` or the VM manager GUI

### Deploy and configure OVAs

* cd into `admin_ws` directory

* Create the `terraform.tfvars` file (example)

  **Please use the variables in the example as it is. Passwords can be found in the Lab doc**

  ```sh
  esxi_public_ip = "192.168.122.200"

  esxi_gw_ip = "192.168.122.1"

  esxi_admin_username = "gkeadmin"

  esxi_admin_password = "CHANGEME"

  esxi_ds_name = "datastore1"

  vcenter_admin_useranme = "administrator@gkeonprem.local"

  vcenter_admin_password = "CHANGEME"

  admin_ws_admin_username = "gkeadmin"

  admin_ws_admin_password = "CHANGEME"

  ova_admin_ws = "http://storage.googleapis.com/nmiu-play_tools/admin-ws-20190308.ova"

  ova_vcsa = "https://storage.googleapis.com/gke-on-prem-lab-ovas/current/vcsa-latest.ova"

  ova_f5 = "https://storage.googleapis.com/gke-on-prem-lab-ovas/current/f5-latest.ova"
  ```

* Run terraform

  ```sh
  terraform init
  terraform plan
  terraform apply
  ```

## Tear down

```sh
cd esxi_kvm
terraform destroy
```
