# Istio with bookinfo

## Prerequesites

[Deplay the cluster and setup the CLI](../)

## Enabling sidecar injection

Istio sidecar auto-injection is disabled for all namespaces by default

```sh
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio-injection: enabled
  name: bookinfo
EOF
```

## Deploy bookinfo

```sh
cd /path/to/istio-1.0.5
kubectl -n bookinfo apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl -n bookinfo apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

* Retrieve the IngressGateway IP

```sh
export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

* Check the app

```sh
curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
```

## What's next

* Apply default destination rules

  The destination rules is required before trying out advance routing featues in the following examples.

  ```sh
  # mutual TLS enabled
  kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
  
  # mutual TLS not enabled
  kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
  ```

* [Intelligent routing](https://istio.io/docs/examples/intelligent-routing/)
* [In-Depth Telemetry](https://istio.io/docs/examples/telemetry/)
* [TLS Origination for Egress Traffic](https://istio.io/docs/examples/advanced-egress/egress-tls-origination/)
* [Configure an Egress Gateway](https://istio.io/docs/examples/advanced-egress/egress-gateway/)

## Teardown

* Delete the application ([how to](https://istio.io/docs/examples/bookinfo/#uninstall-from-kubernetes-environment))
* Delete the `istio-ingressgateway` ingress service

  > This is required to remove the auto-generated `nlb`

  ```sh
  kubectl -n istio-system delete service istio-ingressgateway
  ```

* Delete the cluster

  ```sh
  gcloud beta container clusters delete asuka
  ```
