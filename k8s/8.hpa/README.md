# HPA

Reusing the `go-web` example created in [1.ingress/svc-cluster](../1.ingress/svc-cluster)

## Usage

```sh
cd /path/to/repo/k8s/8.hpa
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