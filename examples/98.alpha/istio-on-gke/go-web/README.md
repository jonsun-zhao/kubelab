# Istio with go-web

## Prerequesites

Go through the steps described in the following sections of the [istio-on-gke](../) example:

* Prerequesites
* Setup

## Deploy

```sh
kubectl apply -f app.yaml
istioctl create -f gateway.yaml
kubectl apply -f destination-rule.yaml
kubectl apply -f vs.yaml
```

* Confirm the app is running

```sh
for i in `seq 1 10`; do curl http://35.192.144.72/ping; sleep 1; echo; done
Hello, world!
Version: v1
Hostname: backend-v1-7cc94b7c67-2wng7

Hello, world!
Version: v1
Hostname: backend-v1-7cc94b7c67-2wng7

Hello, world!
Version: v1
Hostname: backend-v1-7cc94b7c67-2wng7

Hello, world!
Version: v1
Hostname: backend-v1-7cc94b7c67-2wng7

Hello, world!
Version: v1
Hostname: backend-v1-7cc94b7c67-2wng7
...
```


## Split traffic

```sh
kubectl apply -f vs-backend-v1-v2.yaml
```

```sh
for i in `seq 1 10`; do curl http://35.192.144.72/ping; sleep 1; echo; done
Hello, world!
Version: v1
Hostname: backend-v1-7cc94b7c67-2wng7

Hello, world!
Version: v2
Hostname: backend-v2-7f5c99d7f-jpc4h

Hello, world!
Version: v2
Hostname: backend-v2-7f5c99d7f-jpc4h

Hello, world!
Version: v1
Hostname: backend-v1-7cc94b7c67-2wng7

Hello, world!
Version: v2
Hostname: backend-v2-7f5c99d7f-jpc4h
...
```

_get timing details from curl_

```sh
for i in `seq 1 10`; do curl -w "@curl-format.txt" http://35.192.144.72/ping; sleep 1; echo; done
```