# IAP

 Add IAP support to the [tls](../tls)

## Prerequisites

* A static IP reserved in GCP (i.e. `asuka`)
* A FQDN points to the static IP  (i.e. `asuka.premium-cloud-support.com`)
* A SSL key/cert pair for the FQDN
* A OAuth 2.0 client ID credentail ([doc](https://cloud.google.com/iap/docs/enabling-kubernetes-howto))

## Deploy

* Create the TLS pair

```sh
openssl req -x509 -newkey rsa:2048 \
  -subj "/C=US/ST=California/L=San Francisco/O=CPS/CN=asuka.premium-cloud-support.com" \
  -keyout tls.key -out tls.crt -days 3650 -nodes -sha256
```

* Create a sercet from the TLS pair

```sh
kubectl create secret tls go-web-tls --cert tls.crt --key tls.key
```

* Create the OAuth cred sercet
  * Download the OAuth client ID credential JSON and extract the following values
    * `client_id`
    * `client_secret`
  * set them as env variables

```sh
client_id=xxx
client_secret=yyy

kubectl create secret generic go-web-iap-secret --from-literal=client_id=$client_id \
    --from-literal=client_secret=$client_secret
```

* Preview the YAML

```sh
kustomize build .
```

* Apply the YAML

```sh
kustomize build . | kubectl apply -f -
```

## Teardown

```sh
kustomize build . | kubectl delete -f -
kubectl delete secret go-web-tls
kubectl delete secret go-web-iap-secret
```