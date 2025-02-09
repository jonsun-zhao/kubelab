# K8s Examples

Each directory contains a k8s example, some of them are powered by [kustomize](https://github.com/kubernetes-sigs/kustomize), which is useful when we need to reuse K8s resources in multiple examples.

## Prerequisites

* [Install kustomize](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/INSTALL.md)
* (optional) [Install golang](https://golang.org/doc/install)
* Clone this repository onto your workstation
* A working GKE cluster (with minimal 3 nodes) or create one as follow

```sh
gcloud container clusters create asuka \
--machine-type=n1-standard-2 \
--num-nodes=3 \
--image-type=COS \
--cluster-version=1.10 \
--tags=ssh \
--preemptible \
--enable-ip-alias \
--create-subnetwork "" \
--enable-autoscaling \
--min-nodes=2 \
--max-nodes=4 \
--scopes default,cloud-platform,cloud-source-repos,service-control
# --enable-stackdriver-kubernetes
# --subnetwork gke-clusters \
# --services-secondary-range-name asuka-services \
# --cluster-secondary-range-name asuka-pods
```

## Usage

Look into the `README.md` in each example for details

## Further reads

* [How to extend an existing example](extension.md)
