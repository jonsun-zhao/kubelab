# How to extend examples

i.e. I want to make the following changes to the `01.ingress/svc-cluster` example

* shrink the deployment's replica to 1
* attach a PVC to the pod

## Create a new dir in `01.ingress/svc-cluster`

```sh
mkdir 01.ingress/svc-cluster/pvc && cd 01.ingress/svc-cluster/pvc
```

## Create YAMLs

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

## Dry-run

```sh
kustomize build .
```

## Deploy

```sh
kustomize build . | kubectl apply -f -
```

## Teardown

```sh
kustomize build . | kubectl delete -f -
```

_More `kustomize` examples can be found [here](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/kustomization.yaml)_