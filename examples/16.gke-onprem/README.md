# Build the Packet Lab with Terraform

## Prerequisites

* Install [govc](https://github.com/vmware/govmomi/tree/master/govc)
* Install [jq](https://stedolan.github.io/jq/download/)
* Install [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
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

*change the `terraform.tfvars` to suit your needs*

### Terraform apply

```sh
terraform init
terraform plan
terraform apply
```

### Configure `nsvm`

```sh
cd ansible/file
ansible-playbook -i inventory.yml nsvm.yml
```

### activate the F5 appliance

```sh
cd ansible/file
ansible-playbook -i inventory.yml f5.yml
```

### Install GKE On-Prem

Follow the `Install GKE On-Prem` section in the Lab Guide

## Tear down

### Terraform destroy

```sh
TF_WARN_OUTPUT_ERRORS=1 terraform destroy
```
