# GKE-OP-on-Packet deployment automation

## Prerequisites

> The following should all be done from you workstation

* Gain access to the v3 lab guide
* Install [govc](https://github.com/vmware/govmomi/tree/master/govc)
* Install [jq](https://stedolan.github.io/jq/download/)
* Install [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* Install [sshpass](https://stackoverflow.com/questions/42835626/to-use-the-ssh-connection-type-with-passwords-you-must-install-the-sshpass-pr)
* Request a [packet.com](https://www.packet.com) account
* Make sure your **SSH key-pair** are located in `~/.ssh` and named as follow
  * `id_rsa`
  * `id_rsa.pub`
* Create a **SSH key**, with the content of your `id_rsa.pub`, in your `packet.com` profile
* Create a **API Key** in your `packet.com` profile
* Get trial licenses from F5 by registering a free trial account (details covered in the lab guide)

## Deployment

### Prepare Terraform variables (`terraform.tfvar`)

```sh
cp terraform.tfvars.template terraform.tfvars
```

* change the `terraform.tfvars` to suit your needs
* [sample `terraform.tfvars`](https://paste.googleplex.com/4809404681551872)
  * **update the `CHANGEME` variables only**

### Deploy ESXi

```sh
terraform init
terraform plan
terraform apply -auto-approve -input=false
```

#### Note down the IPs returned from `terraform apply`

* ESXi public IP
* NetServiceVM public IP

### Configure `nsvm` and deploy the rest of the infrastructure VMs

```sh
cd ansible/files
ansible-playbook -i inventory.yml nsvm.yml
```

### Activate the F5 appliance

```sh
cd ansible/files
ansible-playbook -i inventory.yml f5.yml
```

### Install GKE On-Prem

Follow the `Install GKE On-Prem` section in the lab guide

## Tear down

### Terraform destroy

```sh
TF_WARN_OUTPUT_ERRORS=1 terraform destroy
```
