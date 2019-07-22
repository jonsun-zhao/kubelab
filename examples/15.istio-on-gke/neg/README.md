# Expose `istio-ingressgateway` on GCP HTTP LB via NEG

## Overview

* The `istio-ingressgateway` service from GKE's istio addon is locked

```sh
→ kubectl -n istio-system get service istio-ingressgateway -o json | jq -r '.metadata.labels."addonmanager.kubernetes.io/mode"'
Reconcile
```

* We will create a seperate `istio-ingressgateway-neg-svc` service to trigger the NEG creation

* Assuming the `istio-ingressgateway` pod is serving the `go-web` app via port `80`
  * Use the [go-web](../go-web) example to setup the application stack

## Deploy

```sh
kubectl apply -f ingressgateway.yaml
```

## Teardown

```sh
kubectl delete -f ingressgateway.yaml
```
