# Provision the ESXi via iPXE

## Prerequisites

* Install [jq](https://stedolan.github.io/jq/download/)
* Request a [packet.com](https://www.packet.com) account
* Make sure your **SSH key-pair** are located in `~/.ssh` and named as follow
  * `id_rsa`
  * `id_rsa.pub`
* Create a **SSH key**, with the content of your `id_rsa.pub`, in your `packet.com` profile
* Create a **API Key** in your `packet.com` profile

## Deploy

* Create the `terraform.tfvars` file from `terraform.tfvars.template`

  ```sh
  packet_auth_token = "CHANGEME"

  packet_project_id = "CHANGEME"

  packet_region = "sjc1"

  packet_device_plan = "c2.medium.x86"

  esxi_hostname = "gkeop-nmiu"

  ipxe_script_url = "http://installers.packet.cloud/gkeop/ipxe"
  ```

* Run terraform

  ```sh
  terraform init
  terraform plan
  terraform apply
  ```

## Tear down

```sh
terraform destroy
```
