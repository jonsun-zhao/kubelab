# Private Cluster with IP alias

## Create the cluster with existing subnet/secondary-range

* Create a subnet in the `default` VPC

  > enable _private ip google access_ in this subnet

  ```sh
  gcloud compute networks subnets create gke-subnet \
    --enable-private-ip-google-access \
    --network default \
    --range 10.50.0.0/16
  ```

* Add secondary ranges to `gke-subnet`

  ```sh
  gcloud compute networks subnets update gke-subnet \
    --add-secondary-ranges asuka-pods=10.51.0.0/16,asuka-services=10.52.0.0/16
  ```

* Create the cluster

  ```sh
  gcloud beta container clusters create asuka \
    --private-cluster \
    --enable-ip-alias \
    --master-ipv4-cidr 172.16.0.32/28 \
    --subnetwork gke-subnet \
    --services-secondary-range-name asuka-services \
    --cluster-secondary-range-name asuka-pods \
    --machine-type=n1-standard-2 \
    --cluster-version=1.10.5-gke.4 \
    --tags=ssh,no-ip \
    --num-nodes=3 \
    --min-nodes=1 \
    --max-nodes=5 \
    --image-type=COS \
    --enable-autoscaling \
    --enable-autorepair \
    --enable-autoupgrade \
    --preemptible \
    --scopes default,cloud-platform,cloud-source-repos,service-control
  ```

* Teardown

```sh
gcloud container clusters delete asuka
# gcloud compute networks subnets update gke-subnet --remove-secondary-ranges asuka-pods,asuka-services
gcloud compute networks subnets delete gke-subnet
```

## Create the cluster with auto-created subnet/seconary-ranges

* Create

```sh
gcloud beta container clusters create asuka \
  --private-cluster \
  --enable-ip-alias \
  --master-ipv4-cidr 172.16.0.16/28 \
  --create-subnetwork "" \
  --machine-type=n1-standard-2 \
  --cluster-version=1.10.5-gke.4 \
  --tags=ssh,no-ip \
  --num-nodes=3 \
  --min-nodes=1 \
  --max-nodes=5 \
  --image-type=COS \
  --enable-autoscaling \
  --enable-autorepair \
  --enable-autoupgrade \
  --preemptible \
  --scopes default,cloud-platform,cloud-source-repos,service-control
```

* Teardown

```sh
gcloud container clusters delete asuka
```

## Create the cluster via terraform

* [Install terraform](https://www.terraform.io/intro/getting-started/install.html)

* Initialize Terraform configuration files in the current directory

```sh
cd 11.private-cluster
terraform init
```

* Modify the `cluster.tf` to suit your needs
  * _you can validate the syntax via `terraform validate`_

* Obtain gcloud application detail credantial

```sh
gcloud auth application-default login
```

* Run terraform

```sh
terraform apply
```

* Teardown

```sh
terraform destory
```

## Enable master authorized networks

_otherwise `kubectl` is unable to reach the master_

```sh
gcloud container clusters update asuka \
  --enable-master-authorized-networks \
  --master-authorized-networks 0.0.0.0/0
```