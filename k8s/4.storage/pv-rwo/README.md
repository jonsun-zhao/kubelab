# PVC - Read Write

## Setup

```sh
kustomize build . | kubectl apply -f -
```

## Teardown

```sh
kustomize build . | kubectl delete -f -
```