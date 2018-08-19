# TLS

Assigning TLS cert/key pair to the ingress

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
kubectl create secret tls go-web-tls --cert tls.crt --key tls.key
```

* Deploy

```sh
kustomize build . | kubectl apply -f -
```

* Teardown

```sh
kustomize build . | kubectl delete -f -
kubectl delete secret go-web-tls
```