# PVC - Read Write

## Usage

```sh
cd /path/to/repo/k8s/4.storage/pv-rwo
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