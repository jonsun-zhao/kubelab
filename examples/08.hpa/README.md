# HPA

Reusing the `go-web` example created in [01.ingress/go-web](../01.ingress/go-web)

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