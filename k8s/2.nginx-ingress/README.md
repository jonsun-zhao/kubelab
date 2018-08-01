# Nginx Ingress Controller

This example demonstrate how nginx-ingress-controller works.

## Usage

```sh
cd /path/to/repo/k8s/2.nginx-ingress
```

### Create the nginx-ingress-controller

* Bind the current user to `cluster-admin` role

_Otherwise `kubectl apply -f nginx-ingress-controller.yaml` will complain about unable to create cluster roles and bindings_

```sh
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
```

* Reserve a static IP

```sh
gcloud compute addresses create nginx-ingress-lb --region us-central1
Created [https://www.googleapis.com/compute/v1/projects/nmiu-play/regions/us-central1/addresses/nginx-ingress-lb].

gcloud compute addresses list | grep nginx-ingress-lb
nginx-ingress-lb                  us-central1  35.224.151.150  RESERVED
```

* Deploy the YAML

_Use the reserved IP as `loadBalancerIP` for the `nginx-ingress-lb` service in `nginx-ingress-controller.yaml`_

```sh
sed "s/RESERVED_IP/35.224.151.150/" nginx-ingress-controller.yaml | kubectl apply -f -
```

### Create a ingress uses the nginx-ingress-controller

* Deploy a `php-apache` app with ingress

```sh
kustomize build . | kubectl apply -f -
```

* Observe the logs from the NIC pods

```sh
kubectl -n kube-system logs nginx-ingress-controller-84d749cdbb-rss5j
-------------------------------------------------------------------------------
NGINX Ingress controller
  Release:    0.17.1
  Build:      git-12f7966
  Repository: https://github.com/kubernetes/ingress-nginx.git
-------------------------------------------------------------------------------

nginx version: nginx/1.13.12
W0725 13:15:30.528484       5 client_config.go:552] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0725 13:15:30.528824       5 main.go:191] Creating API client for https://10.47.240.1:443
I0725 13:15:30.543131       5 main.go:235] Running in Kubernetes cluster version v1.10+ (v1.10.5-gke.2) - git (clean) commit f199298d18103a59db32d97a92072fbb17b1175a - platform linux/amd64
I0725 13:15:30.545950       5 main.go:100] Validated kube-system/default-http-backend as the default backend.
I0725 13:15:31.024509       5 nginx.go:255] Starting NGINX Ingress controller
I0725 13:15:31.048442       5 event.go:221] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"kube-system", Name:"udp-services", UID:"c0eaec96-900c-11e8-bb21-42010a80015f", APIVersion:"v1", ResourceVersion:"956039", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap kube-system/udp-services
I0725 13:15:31.048709       5 event.go:221] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"kube-system", Name:"tcp-services", UID:"c09416f7-900c-11e8-bb21-42010a80015f", APIVersion:"v1", ResourceVersion:"956036", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap kube-system/tcp-services
I0725 13:15:31.048806       5 event.go:221] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"kube-system", Name:"nginx-configuration", UID:"c03d0fe2-900c-11e8-bb21-42010a80015f", APIVersion:"v1", ResourceVersion:"956034", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap kube-system/nginx-configuration
I0725 13:15:32.225555       5 nginx.go:276] Starting NGINX process
I0725 13:15:32.225919       5 leaderelection.go:185] attempting to acquire leader lease  kube-system/ingress-controller-leader-nginx...
I0725 13:15:32.228867       5 controller.go:169] Configuration changes detected, backend reload required.
I0725 13:15:32.233346       5 status.go:197] new leader elected: nginx-ingress-controller-669b5b6f45-jglx7
I0725 13:15:32.367496       5 controller.go:185] Backend successfully reloaded.
...
I0725 13:37:08.263304       5 controller.go:169] Configuration changes detected, backend reload required.
I0725 13:37:08.267706       5 event.go:221] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"nic-ing", UID:"74793f5c-900d-11e8-bb21-42010a80015f", APIVersion:"extensions/v1beta1", ResourceVersion:"958563", FieldPath:""}): type: 'Normal' reason: 'UPDATE' Ingress default/nic-ing
I0725 13:37:08.407333       5 controller.go:185] Backend successfully reloaded.
```

* curl test

```sh
curl -v http://35.224.151.150/test -H "Host: example.com"
*   Trying 35.224.151.150...
* TCP_NODELAY set
* Connected to 35.224.151.150 (35.224.151.150) port 80 (#0)
> GET /test HTTP/1.1
> Host: example.com
> User-Agent: curl/7.60.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.13.12
< Date: Wed, 25 Jul 2018 13:37:34 GMT
< Content-Type: text/html; charset=UTF-8
< Content-Length: 32
< Connection: keep-alive
< X-Powered-By: PHP/7.2.8
<
* Connection #0 to host 35.224.151.150 left intact
host => nic-dep-58bc5f5b77-4shnj%
```

* Observe the access log from the `nginx-ingress-controller-xxx-xxx` pods

```sh
124.149.190.141 - [124.149.190.141] - - [25/Jul/2018:13:37:34 +0000] "GET /test HTTP/1.1" 200 32 "-" "curl/7.60.0" 79 0.030 [default-nic-svc-80] 10.44.17.37:80 32 0.030 200 56b3bf5ecdca5b786377fd1e2df86950
```

## Teardown

* teardown the app

```sh
kustomize build . | kubectl delete -f -
```

* teardown the nginx-ingress-controller

```sh
kubectl delete -f nginx-ingress-controller.yaml
```