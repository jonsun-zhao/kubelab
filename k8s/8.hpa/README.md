# HPA

Reusing the `go-web` example created in [1.ingress/svc-cluster](../1.ingress/svc-cluster)

## Deploy

```sh
kustomize build . | kubectl apply -f -
```

## Teardown

```sh
kustomize build . | kubectl delete -f -
```