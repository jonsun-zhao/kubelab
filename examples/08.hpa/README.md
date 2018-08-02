# HPA

Reusing the `go-web` example created in [01.ingress/svc-cluster](../01.ingress/svc-cluster)

## Usage

```sh
cd 8.hpa
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