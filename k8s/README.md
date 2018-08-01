# K8s Examples

Each directory contains a k8s example, some of them are powered by [kustomize](https://github.com/kubernetes-sigs/kustomize), which is useful when we need to reuse K8s resources in multiple examples.

## Prerequisites

* [Install kustomize](https://github.com/kubernetes-sigs/kustomize/blob/master/INSTALL.md)
* (optional) [Install golang](https://golang.org/doc/install)
* Clone this repository onto your workstation

## How to run the example

* complex examples have `README.md`, details can be found there
* simple examples doesn't need `README.md`, just use the following commands to deploy/teardown objects

### Sample Usage

```sh
# cd into the k8s directory
cd /path/to/repo/k8s

# dry run
kustomize build 1.ingress/svc-cluster

# deploy
kustomize build 1.ingress/svc-cluster | kubectl apply -f -

# teardown
kustomize build 1.ingress/svc-cluster | kubectl delete -f -
```

---

## How to extend the examples

I.E. I want to make the following changes to the `1.ingress/svc-cluster` example

* shrink the deployment's replica to 1
* attach a PVC to the pod

### Create a new dir in `1.ingress/svc-cluster`

```sh
mkdir 1.ingress/svc-cluster/pvc && cd 1.ingress/svc-cluster/pvc
```

### Create YAMLs

* `kustomization.yaml`

> `kustomization.yaml` defines:
> * the example is based upon `svc-cluster`
> * a new `pvc.yaml` is added
> * use `patch.yaml` to modify the existing `go-web-dep` deployment in `svc-cluster`

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

_Only the changed bits are required in the `patch.yaml`_

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

### Dryrun

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