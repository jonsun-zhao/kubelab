# HTTPS

Istio TLS ingress gateway (<= 1.0)

## Prerequisites

```sh
# create crt and key
pushd cd /tmp
openssl req -x509 -newkey rsa:2048 \
  -subj "/C=US/ST=California/L=San Francisco/O=CPS/CN=*.example.com" \
  -keyout tls.key -out tls.crt -days 3650 -nodes -sha256

# create sercret from crt/key
kubectl -n istio-system create secret tls istio-ingressgateway-certs --cert tls.crt --key tls.key

# create ca-secret from crt
kubectl -n istio-system create secret generic istio-ingressgateway-ca-certs --from-file=tls.crt
popd
```

## Deploy

```sh
make apply
```

## Verify

* Retrieve the IngressGateway IP

```sh
export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

* Check HTTP

```sh
→ curl http://$GATEWAY_URL
Hello, world!
Version: 1.0.0
Hostname: frontend-7dd7d9c4fb-5c5z4

== Header ==
GET / HTTP/1.1
Host: 35.192.112.49
Accept: */*
Content-Length: 0
User-Agent: curl/7.54.0
X-B3-Sampled: 0
X-B3-Spanid: a5e8bb76125b435e
X-B3-Traceid: a5e8bb76125b435e
X-Envoy-Internal: true
X-Forwarded-For: 10.112.28.42
X-Forwarded-Proto: http
X-Request-Id: bcd80204-d051-4108-a314-201194ee77bd
```

* Check HTTPS (`asuka.example.com`)

```sh
→ curl -k https://asuka.example.com --resolve "asuka.example.com:443:$GATEWAY_URL"
Hello, world!
Version: 1.0.0
Hostname: frontend-7dd7d9c4fb-5c5z4

== Header ==
GET / HTTP/1.1
Host: asuka.example.com
Accept: */*
Content-Length: 0
User-Agent: curl/7.54.0
X-B3-Sampled: 0
X-B3-Spanid: c9f8722b2b81fb5f
X-B3-Traceid: c9f8722b2b81fb5f
X-Envoy-Internal: true
X-Forwarded-For: 10.112.28.42
X-Forwarded-Proto: https
X-Request-Id: 646dd2c2-a91c-4ba9-9942-c8b3e2104065
```

* Check a rogue HTTPS

```sh
→ curl -k https://asuka.example.co --resolve "asuka.example.co:443:$GATEWAY_URL"
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to asuka.example.co:443
```

## Teardown

```sh
make clean
```
