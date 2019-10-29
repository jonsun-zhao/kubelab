# How to extend playbooks

For example, I want to make the following changes to `02.ingress/go-web`

* shrink the deployment's replica to 1
* attach a PVC to the pod

## Create a new dir in `02.ingress/go-web`

```sh
mkdir 02.ingress/go-web/pvc && cd 02.ingress/go-web/pvc
```

## Create YAMLs

* `kustomization.yaml`

> `kustomization.yaml` defines:
> * the example is based upon `go-web`
> * a new `pvc.yaml` is added
> * use `patch.yaml` to modify the existing `go-web-dep` deployment in `go-web`

```yaml
bases:
- ../../go-web
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

_More `kustomize` playbooks can be found [here](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/kustomization.yaml)_