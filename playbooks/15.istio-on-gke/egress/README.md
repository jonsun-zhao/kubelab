# Istio egress

Egress to destinations outside of the mesh

## Prerequisites

* a clean GKE Cluster with istio auth set to strict

  ```sh
  gcloud beta container clusters create asuka \
    --machine-type=n1-standard-2 \
    --num-nodes=3 \
    --image-type=COS \
    --cluster-version=1.12 \
    --tags=ssh \
    --addons=Istio,HttpLoadBalancing --istio-config=auth=MTLS_STRICT \
    --preemptible \
    --enable-ip-alias \
    --create-subnetwork "" \
    --enable-network-policy \
    --scopes cloud-platform
  ```

* an auto-injection enabled namespace

  ```sh
  cat << EOF | kubectl apply -f -
  ---
  apiVersion: v1
  kind: Namespace
  metadata:
    labels:
      istio-injection: enabled
    name: istio-workload
  EOF
  ```

* deploy the test pod `hammer`

  ```sh
  kubectl apply -f app.yaml
  ```

* an functioning `ILB` service outside of the mesh

  In this example, `10.10.0.4` is a ILB type service provided by a another GKE cluster. It responds to both HTTP and HTTPS

  ```sh
  $ curl http://10.10.0.4; echo
  host => php-apache-dep-6c5475744d-xmthn

  $ curl -k -s https://10.10.0.4; echo
  host => php-apache-dep-6c5475744d-xmthn
  ```

## Option 1

* Brought the ILB service into the mesh via a headless service `svc-foo.istio-workload.svc.cluster.local`

  ```sh
  kubectl apply -f service.yaml
  ```

  Try it out in the pod `hammer` reveal a few things:

  ```sh
  [root@hammer-685c54dd9c-csrfq ~]# curl -Is http://10.10.0.4
  HTTP/1.1 404 Not Found
  date: Mon, 29 Apr 2019 03:39:59 GMT
  server: envoy
  transfer-encoding: chunked

  [root@hammer-685c54dd9c-csrfq ~]# curl -Is http://svc-foo.istio-workload.svc.cluster.local
  HTTP/1.1 503 Service Unavailable
  content-length: 57
  content-type: text/plain
  date: Mon, 29 Apr 2019 03:40:23 GMT
  server: envoy
  ```

  * curl to `10.10.0.4` returns *404*
    * This is because the service is headless, `10.10.0.4` is an **endpoint** instead of a **route**.
    * No route matching `10.10.0.4` can be found in RDS (`istioctl proxy-config route -n istio-workload hammer-xxx`

  * curl to `svc-foo.istio-workload.svc.cluster.local` returns *503*
    * This is because `istio-proxy` is trying to reach the ILB service with `mTLS` enabled, while the service is outside of the mesh

    ```sh
    istioctl authn tls-check svc-foo.istio-workload.svc.cluster.local
    HOST:PORT                                       STATUS     SERVER     CLIENT     AUTHN POLICY     DESTINATION RULE
    svc-foo.istio-workload.svc.cluster.local:80     OK         mTLS       mTLS       default/         default/istio-system
    ```

* Apply a `DestinationRule` to disable `mTLS` from the client side

  As a result, `istio-proxy` from `hammer` will **NOT** encrypt communications targeting `svc-foo.istio-workload.svc.cluster.local`

  ```sh
  kubectl apply -f destination_rule.yaml
  ```

  TLS check reveals that the client is no longer using mTLS.

  ```sh
  istioctl authn tls-check svc-foo.istio-workload.svc.cluster.local
  HOST:PORT                                       STATUS       SERVER     CLIENT     AUTHN POLICY     DESTINATION RULE
  svc-foo.istio-workload.svc.cluster.local:80     CONFLICT     mTLS       HTTP       default/         destinationrule-foo/istio-workload
  ```

  Tests on the pod works

  ```sh
  [root@hammer-685c54dd9c-csrfq ~]# curl -Is http://svc-foo.istio-workload.svc.cluster.local
  HTTP/1.1 200 OK
  date: Mon, 29 Apr 2019 03:54:45 GMT
  server: envoy
  x-powered-by: PHP/7.2.8
  content-type: text/html; charset=UTF-8
  x-envoy-upstream-service-time: 719
  transfer-encoding: chunked

  [root@hammer-685c54dd9c-csrfq ~]# curl -Isk https://svc-foo.istio-workload.svc.cluster.local
  HTTP/1.1 200 OK
  Date: Mon, 29 Apr 2019 03:55:01 GMT
  Server: Apache/2.4.25 (Debian)
  X-Powered-By: PHP/7.2.8
  Content-Type: text/html; charset=UTF-8
  ```

## Option 2

Regarding inbound/outbound traffic to/from a pod, it is possible to bypass the istio-proxy redirection completely with [annotations](https://istio.io/docs/setup/kubernetes/additional-setup/cni/#traffic-redirection-details)

By adding the `traffic.sidecar.istio.io/excludeOutboundIPRanges: "10.10.0.4/32"` to the pod template, outbound traffic to the ILB service will not flow through

```sh
kubectl delete -f destination_rule.yaml
destinationrule.networking.istio.io "destinationrule-foo" deleted

kubectl apply -f app_annotated.yaml
deployment.extensions "hammer" configured
```

Tests on the new hammer pod works

```sh
[root@hammer-6b566b8ccb-mqk8j ~]# curl -Is http://svc-foo.istio-workload.svc.cluster.local
HTTP/1.1 200 OK
Date: Mon, 29 Apr 2019 04:08:54 GMT
Server: Apache/2.4.25 (Debian)
X-Powered-By: PHP/7.2.8
Content-Type: text/html; charset=UTF-8

[root@hammer-6b566b8ccb-mqk8j ~]# curl -Isk https://svc-foo.istio-workload.svc.cluster.local
HTTP/1.1 200 OK
Date: Mon, 29 Apr 2019 04:10:24 GMT
Server: Apache/2.4.25 (Debian)
X-Powered-By: PHP/7.2.8
Content-Type: text/html; charset=UTF-8
```

The rule that bypass the istio-proxy can be seen from `iptables` in the hammer pod

```sh
[root@hammer-6b566b8ccb-mqk8j ~]# iptables-save
...
*nat
:PREROUTING ACCEPT [1:60]
:INPUT ACCEPT [1:60]
:OUTPUT ACCEPT [206:20576]
:POSTROUTING ACCEPT [206:20576]
:ISTIO_IN_REDIRECT - [0:0]
:ISTIO_OUTPUT - [0:0]
:ISTIO_REDIRECT - [0:0]
-A OUTPUT -p tcp -j ISTIO_OUTPUT
-A ISTIO_IN_REDIRECT -p tcp -j REDIRECT --to-ports 15001
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -j ISTIO_REDIRECT
-A ISTIO_OUTPUT -m owner --uid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -m owner --gid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -d 10.10.0.4/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
-A ISTIO_REDIRECT -p tcp -j REDIRECT --to-ports 15001
COMMIT
```

## Clean up

```sh
make clean
```