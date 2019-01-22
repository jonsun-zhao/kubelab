# Deploy the vsphere environment

## Prepare keys

* Place your SSH key-pair in `~/.ssh` and name them
  * `id_rsa`
  * `id_rsa.pub`

* Add the **Public SSH Key** to your `packet.com` profile
* Create a **API Key** in your `packet.com` profile

## Modify the `main.cf`

> Annoyingly the `packet_volume` resource doesn't support `name` argument, thus you have to change the existing `packet_volume` name to something unique

```sh
# Linux
sed -i "s/datastore/YOUR_VOLUME_NAME/g" *.tf

# Mac
sed -i '' "s/datastore/YOUR_VOLUME_NAME/g" *.tf
```

## Create the `terraform.tfvar`

```sh
cp terraform.tfvars.template terraform.tfvars
```

* Make necessary changes to the `terraform.tfvars` (*i.e.*)

  ```sh
  packet_auth_token = "YOUR_PACKET_API_KEY"
  packet_project_id = "231a57e1-a348-43ce-9b26-b1238e82dc4c"
  packet_plan_name = "c2.medium.x86"

  esxi_hostname = "YOUR_ESXI_HOSTNAME"
  esxi_admin_username = "gkeadmin"
  esxi_admin_passwordd = "YOUR_ESXI_ADMIN_PASSWORD"
  ```

## Deploy

```sh
terraform init
terraform apply
```
