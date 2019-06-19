# GRPC over HTTP/2 Ingress

>NOTE: GRPC over HTTP/2 **requires** TLS

## Prerequisites

* A static IP reserved in GCP (i.e. `asuka`)
* A FQDN points to the static IP  (i.e. `asuka.premium-cloud-support.com`)
* A SSL key/cert pair for the FQDN

```sh
openssl req -x509 -newkey rsa:2048 \
  -subj "/C=US/ST=California/L=San Francisco/O=CPS/CN=asuka.premium-cloud-support.com" \
  -keyout tls.key -out tls.crt -days 3650 -nodes -sha256
```

* Create the sercet

```sh
kubectl create secret tls premium-cloud-support-com-tls --cert tls.crt --key tls.key
```

## Deploy

```sh
kustomize build . | kubectl apply -f -
```

## Verification

* review the log from the `routeguide-client` pods
* test the client against the HTTP LB

```sh
cd /path/to/kubelab/apps/go-routeguide/src/route_guide
go run client/client.go --ca_file=/path/to/tls.crt --server_host_override=asuka.premium-cloud-support.com --tls --server_addr=asuka.premium-cloud-support.com:443
```

## Teardown

```sh
kustomize build . | kubectl delete -f -
```