# Service

## Examples

* [clusterip](clusterip)
  * Service with type `ClusterIP`
* [internal-lb](internal-lb)
  * Service with GCP Internal Loadbalancer

## Usage

```sh
cd /path/to/repo/k8s/3.service/clusterip # or internal-lb
```

* dry-run

```sh
kustomize build .
```

* deploy

```sh
kustomize build . | kubectl apply -f -
```

* teardown

```sh
kustomize build . | kubectl delete -f -
```