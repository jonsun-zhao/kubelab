# HPA

Reusing the `go-web` example created in [01.ingress/svc-cluster](../01.ingress/svc-cluster)

## Usage

* preview

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