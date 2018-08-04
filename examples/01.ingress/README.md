# Ingress

## Examples

* [svc-cluster](svc-cluster)
  * Ingress backed by a `nodePort` service with `externalTrafficPolicy` set to `Cluster`
  * Service is provided by a `go-web` deployment backed by mongodb
* [svc-local](svc-local)
  * Ingress backed by a `nodePort` service with `externalTrafficPolicy` set to `Local`
  * Service is provide by a `php-apache` deployement

## Usage

```sh
cd svc-cluster # or svc-local
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