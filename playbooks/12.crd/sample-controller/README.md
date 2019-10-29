# sample-controller

Upstream: [simple controller example](https://github.com/kubernetes/sample-controller)

## Purpose

An example of how to build a kube-like controller with a single type.

- We are going to deploys a `example-controller` which implements the API resource `Foo` in K8s.
- API resource `Foo`, as well as its API group `samplecontroller.k8s.io`, are created as CustomResourceDefinition (CRD)
- When resource `Foo` is available in K8s API, we can then *create/update/remove* API objects of `Foo`, which subsequently creates functional `go-web` applications.

## Architecture

- [sample-controller](https://docs.google.com/drawings/d/1ZAv0xfXusNso0dyluaeWvNjK-8h-kRfQda-eeY-5wsA/edit?usp=sharing)
  ![graph](images/crd_sample_controller.png)
- custom controller internals
  ![graph](images/custom_controller.jpeg)

## Deploy

- Install the controller

```sh
kustomize build . | kubectl apply -f -
```

- Create CRD

```sh
kubectl apply -f crd.yaml
```

- Create Foo

```sh
kubectl apply -f foo.yaml
```

## Teardown

```sh
kustomize build . | kubectl delete -f -
```
