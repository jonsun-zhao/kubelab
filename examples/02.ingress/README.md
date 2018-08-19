# Ingress

## What is Ingress

_(from the OSS doc)_

An Ingress is a collection of rules that allow inbound connections to reach the services.

![Ingress Dataplane](images/ingress.png)

It can be configured to give services externally-reachable URLs, load balance traffic, terminate SSL, offer name based virtual hosting, and more.

In GCP, a `Ingress` creates a `HTTP Load Balancer (L7)`, which directs the traffic to the backend nodes on the port exposed by a `NodePort` or `LoadBalancer` type service.

## Examples

* [go-web](go-web)
  * Ingress backed by a `nodePort` service with `externalTrafficPolicy` set to `Cluster`
  * Service is provided by a `go-web` deployment backed by mongodb
    * Variances
      * [iap](go-web/iap) - enable IAP via Ingress
      * [pvc](go-web/pvc) - use a PVC for stroage
      * [tls](go-web/tls) - attach TLS to the Ingress
* [php-apache](php-apache)
  * Ingress backed by a `nodePort` service with `externalTrafficPolicy` set to `Local`
  * Service is provide by a `php-apache` deployement

## Usage

```sh
cd go-web
```

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