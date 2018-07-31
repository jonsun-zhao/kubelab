# K8s Examples

Each directory contains a k8s example, some of them are powered by [kustomize](https://github.com/kubernetes-sigs/kustomize), which is useful when we need to reuse K8s resources in multiple examples.

## Prerequisites

* [Install kustomize](https://github.com/kubernetes-sigs/kustomize/blob/master/INSTALL.md)
* (optional) [Install golang](https://golang.org/doc/install)

## How to run the example

* complex examples have `README.md`, details can be found in there
* simple doesn't need `README.md`, just use the following commands to deploy/teardown objects

```sh
# deploy
kustomize build <EXAMPLE> | kubectl apply -f -

# teardown
kustomize build <EXAMPLE> | kubectl delete -f -
```

## How to customize the examples

I.E. I want to make the following changes to the `1.ingress/svc-cluster` example

* shrink the deployment's replica to 1
* attach a PVC to the pod

### create a new dir in `1.ingress/svc-cluster`

```sh
mkdir 1.ingress/svc-cluster/pvc && cd 1.ingress/svc-cluster/pvc
```

### Create YAMLs

* `kustomization.yaml`

> `kustomization.yaml` defines:
> * the example is based upon `svc-cluster`
> * a new `pvc.yaml` is added
> * use `patch.yaml` to modify the existing `dep` deployment in `svc-cluster`

```yaml
bases:
- ../../svc-cluster
resources:
- pvc.yaml
patches:
- patch.yaml
```

* `pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: go-web-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```

* `patch.yaml`

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: go-web-dep
spec:
  replicas: 1
  template:
    spec:
      containers:
        - name: go-web
          volumeMounts:
          - name: data
            mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: go-web-pvc
```

### Dry-run

```sh
kustomize build .
```

### Deploy

```sh
kustomize build . | kubectl apply -f -
```

### Teardown

```sh
kustomize build . | kubectl delete -f -
```

_More `kustomize` examples can be found [here](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/kustomization.yaml)_