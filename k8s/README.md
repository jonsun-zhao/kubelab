# K8s Examples

Each directory contains a k8s example, some of them are powered by [kustomize](https://github.com/kubernetes-sigs/kustomize), which is useful when we need to reuse K8s resources in multiple examples.

## How to run the example

```sh
kustomize build <EXAMPLE> | kubectl apply -f -
```

## How to extend examples powered by `kustomize`

For example, I want to update the `6.go-web` example with the following requirements:

* shrink the deployment's replica to 1
* attach a PVC to the go-web pod

### cd into `6.go-web`

```sh
cd 6.go-web
```

### Locate the base resources

> `6.go-web` is using base resources from `apps/go-web/k8s`

* `kustomization.yaml`

```yaml
bases:
- ../../apps/go-web/k8s
...
```

### Create the PVC

> Save the following YAML as `pvc.yaml` and reference it in `kustomization.yaml`

* `pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```

* `kustomization.yaml`

```yaml
bases:
- ../../apps/go-web/k8s
resources:
- ingress.yaml
- pvc.yaml
patches:
- patch.yaml
namePrefix: go-web-
```

### Customize the deployment in `patch.yaml`

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: dep
spec:
  replicas: 1
  template:
    spec:
      containers:
        - name: go-web
          env:
            - name: MONGODB_URL
              value: go-web-mongodb
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

### Run

```sh
kustomize build . | kubectl apply -f -
```

### More `kustomize` examples can be found [here](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/kustomization.yaml)

## Teardown

```sh
kustomize build . | kubectl delete -f -
```
