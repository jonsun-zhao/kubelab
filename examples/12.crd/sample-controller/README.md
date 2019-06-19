# sample-controller

Upstream: [simple controller example](https://github.com/kubernetes/sample-controller)

The example deploys a `example-controller` deployment which is watching `Foo` resources as defined with a CustomResourceDefinition (CRD), and create/update/remove a test `example-foo` deployment.

## Installation

* Install the controller

```sh
cd /path/to/kubelab/apps/sample-controller
kubectl apply -f app.yaml
```

* Deploy CRD and test

```sh
kubectl apply -f crd.yaml
kubectl apply -f example-foo.yaml
```
