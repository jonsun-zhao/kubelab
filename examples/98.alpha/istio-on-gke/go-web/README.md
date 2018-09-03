# Istio with go-web

## Prerequesites

Go through the steps described in the following sections of the [istio-on-gke](../) example:

* Prerequesites
* Setup

## Deploy

```sh
make apply
```

* Get the IngressGateway IP

```sh
export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o template --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
```

* Confirm the app is running

```sh
curl -s http://$GATEWAY_URL/ping

Reaching backend: http://backend:8000

== Result ==
Hello, world!
Version: v1
Hostname: backend-v1-f857c7c8-sfgfw

== Header ==
GET / HTTP/1.1
Host: backend:8000
Accept-Encoding: gzip
Content-Length: 0
User-Agent: Go-http-client/1.1
X-B3-Sampled: 1
X-B3-Spanid: d87a6427651e2ecd
X-B3-Traceid: d87a6427651e2ecd
X-Envoy-Expected-Rq-Timeout-Ms: 15000
X-Forwarded-Proto: http
X-Request-Id: cef7ac4b-756c-99a5-93e2-b362aad09cd9
```

## Split traffic

```sh
kubectl apply -f vs-backend-v1-v2.yaml
```

```sh
for i in `seq 1 5`; do curl -s http://$GATEWAY_URL/ping | grep -A1 Version ; sleep 1; echo; done
Version: v1
Hostname: backend-v1-f857c7c8-sfgfw

Version: v2
Hostname: backend-v2-67cc94b87b-g6gsq
...
```

## Fault Injection

### Delay the response when the request contains a specific header

* `7` seconds delay is injected to a request with header of `foo: bar` when it reaches the backend

  ```sh
  kubectl apply -f vs-backend-delay.yaml
  ```

* Test without the header

  ```sh
  curl -w "@curl-format.txt" http://$GATEWAY_URL/ping

  Reaching backend: http://backend:8000

  == Result ==
  Hello, world!
  Version: v1
  Hostname: backend-v1-f857c7c8-z5cvk

  == Header ==
  GET / HTTP/1.1
  Host: backend:8000
  Accept-Encoding: gzip
  Content-Length: 0
  User-Agent: Go-http-client/1.1
  X-B3-Sampled: 1
  X-B3-Spanid: 6d94f2dabc9dec9a
  X-B3-Traceid: 6d94f2dabc9dec9a
  X-Envoy-Expected-Rq-Timeout-Ms: 15000
  X-Forwarded-Proto: http
  X-Request-Id: 359127b6-72e7-9f6c-8b82-bb092c4898e1

      time_namelookup:  0.004949
        time_connect:  0.279441
      time_appconnect:  0.000000
    time_pretransfer:  0.279511
        time_redirect:  0.000000
  time_starttransfer:  0.587207
                      ----------
          time_total:  0.587305
  ```

* Test with the header

  ```sh
  curl -H "foo: bar" -w "@curl-format.txt" http://$GATEWAY_URL/ping
  
  Reaching backend: http://backend:8000

  == Result ==
  Hello, world!
  Version: v2
  Hostname: backend-v2-67cc94b87b-nlpls

  == Header ==
  GET / HTTP/1.1
  Host: backend:8000
  Accept-Encoding: gzip
  Content-Length: 0
  Foo: bar
  User-Agent: Go-http-client/1.1
  X-B3-Sampled: 1
  X-B3-Spanid: 0f2023c97f0a6882
  X-B3-Traceid: 0f2023c97f0a6882
  X-Envoy-Expected-Rq-Timeout-Ms: 15000
  X-Forwarded-Proto: http
  X-Request-Id: 60c0d79e-ac33-9967-84cb-9883b2033fe2

      time_namelookup:  0.004470
        time_connect:  0.234430
      time_appconnect:  0.000000
    time_pretransfer:  0.234504
        time_redirect:  0.000000
  time_starttransfer:  7.478905
                      ----------
          time_total:  7.479019
  ```

### Abort the request if a specific header is set
  
* Envoy abort a request with header `foo: bar` when it reaches the backend

  ```sh
  kubectl apply -f vs-backend-fault.yaml
  ```

* Test without the header

  ```sh
  curl -s http://$GATEWAY_URL/ping

  Reaching backend: http://backend:8000

  == Result ==
  Hello, world!
  Version: v1
  Hostname: backend-v1-f857c7c8-sfgfw

  == Header ==
  GET / HTTP/1.1
  Host: backend:8000
  Accept-Encoding: gzip
  Content-Length: 0
  User-Agent: Go-http-client/1.1
  X-B3-Sampled: 1
  X-B3-Spanid: 0a0e3e0f41f9f9f3
  X-B3-Traceid: 0a0e3e0f41f9f9f3
  X-Envoy-Expected-Rq-Timeout-Ms: 15000
  X-Forwarded-Proto: http
  X-Request-Id: a68da7cb-eda8-977c-972f-9e78e72c55ab
  ```

* Test with the header

  ```sh
  curl -H "foo: bar" -s http://$GATEWAY_URL/ping

  Reaching backend: http://backend:8000

  == Result ==
  fault filter abort
  ```

## Teardown

* Delete the application

  ```sh
  kubectl delete -f app.yaml
  ```

* Delete the `istio-ingressgateway` ingress service

  ```sh
  kubectl -n istio-system delete service istio-ingress
  kubectl -n istio-system delete service istio-ingressgateway
  ```

* Delete the cluster using the same service account that creates it

  ```sh
  gcloud config set account ${SA}@${PROJECT_ID}.iam.gserviceaccount.com
  ```

  ```sh
  gcloud alpha container clusters delete asuka
  ```