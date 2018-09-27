# Istio on GKE (alpha)

## Prerequisites

> this alpha feature can only be used via service account

```sh
PROJECT_ID=nmiu-play
SA=my-cluster-admin
```

### Create the service account and bind it to roles

```sh
gcloud iam service-accounts create ${SA} --display-name=${SA}
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${SA}@${PROJECT_ID}.iam.gserviceaccount.com --role=roles/container.clusterAdmin
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${SA}@${PROJECT_ID}.iam.gserviceaccount.com --role=roles/iam.serviceAccountActor
```

### Fetch the service account key

```sh
gcloud iam service-accounts keys create ${SA}-private-key.json --iam-account=${SA}@${PROJECT_ID}.iam.gserviceaccount.com
```

### Activate the service account in gcloud

```sh
gcloud auth activate-service-account ${SA}@${PROJECT_ID}.iam.gserviceaccount.com --key-file=${SA}-private-key.json
```

### Force gcloud to use the alpha api for container

```sh
gcloud config set container/use_v1_api false
```

> Note: If you have the updated version, the previous command results in an error:
> ```sh
> ERROR: (gcloud.config.set) Section [container] has no property [use_v1_api].
> ```
> You can safely ignore it.

### Check if alpha api is woriing

```sh
gcloud alpha container clusters list --log-http
```

* [reference](https://cloud.google.com/kubernetes-engine/docs/reference/api-organization#beta)

## Setup

### Option 1

Enable Istio with security when creating a cluster

```sh
gcloud alpha container clusters create asuka \
--machine-type=n1-standard-2 \
--num-nodes=3 \
--image-type=COS \
--cluster-version=1.10 \
--tags=ssh \
--addons=Istio,HttpLoadBalancing --istio-config=auth=MUTUAL_TLS \
--preemptible \
--enable-ip-alias \
--create-subnetwork "" \
--scopes default,cloud-platform,cloud-source-repos,service-control
```

### Option 2

Enabling Istio **without** security when creating a cluster

```sh
gcloud alpha container clusters create asuka \
--machine-type=n1-standard-2 \
--num-nodes=3 \
--image-type=COS \
--cluster-version=1.10 \
--tags=ssh \
--addons=Istio,HttpLoadBalancing --istio-config=auth=None \
--preemptible \
--enable-ip-alias \
--create-subnetwork "" \
--scopes default,cloud-platform,cloud-source-repos,service-control
```

## Deploy sample application

* Grab latest Istio in order to get samples

  ```sh
  curl -L https://git.io/getLatestIstio | sh -
  ```

* Next, change into the directory that just got created

  ```sh
  cd istio-1.0.0
  ```

* Add the istioctl client to your PATH

  ```sh
  export PATH=$PATH:$PWD/bin
  ```

* Deploy the Bookinfo sample application to your cluster.
  * The examples can be found in the uncompressed `istio-1.0.0` directory
  * Or you can get it from [GitHub](https://github.com/istio/istio)

  ```sh
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
  ```

* Now deploy the gateway

  ```sh
  istioctl create -f samples/bookinfo/networking/bookinfo-gateway.yaml
  ```

* Now ensure that the BookInfo sample was deployed

  ```sh
  kubectl get pods

  NAME                           READY     STATUS    RESTARTS   AGE
  details-v1-6865b9b99d-hvkwl    2/2       Running   0          20h
  productpage-v1-f8c8fb8-fjb6f   2/2       Running   0          1d
  ratings-v1-77f657f55d-2c56r    2/2       Running   0          25m
  reviews-v1-6b7f6db5c5-cnmx2    2/2       Running   0          20h
  reviews-v2-7ff5966b99-plqvj    2/2       Running   0          1d
  reviews-v3-5df889bcff-njgbk    2/2       Running   0          25m
  ```

* Verify the sidecars are auto-injected into these pods

  ```sh
  kubectl get pods productpage-v1-f8c8fb8-fjb6f -o yaml | grep image
      sidecar.istio.io/status: '{"version":"51906d82df1d11efdee0076b5f1ae634793093e5075eb5ab2479a638dbb202ff","initContainers":["istio-init"],"containers":["istio-proxy"],"volumes":["istio-envoy","istio-certs"],"imagePullSecrets":null}'
    - image: istio/examples-bookinfo-productpage-v1:1.8.0
      imagePullPolicy: IfNotPresent
      image: gcr.io/gke-release/istio/proxyv2:0.8.0-gke.1
      imagePullPolicy: IfNotPresent
      image: gcr.io/gke-release/istio/proxy_init:0.8.0-gke.1
      imagePullPolicy: IfNotPresent
      image: gcr.io/gke-release/istio/proxyv2:0.8.0-gke.1
      imageID: docker-pullable://gcr.io/gke-release/istio/proxyv2@sha256:93bf83eef6ce267fd091f61183d4432dfb93c2981d2fa1a856d8f616df0f6378
      image: istio/examples-bookinfo-productpage-v1:1.8.0
      imageID: docker-pullable://istio/examples-bookinfo-productpage-v1@sha256:ed65a39f8b3ec5a7c7973c8e0861b89465998a0617bc0d0c76ce0a97080694a9
      image: gcr.io/gke-release/istio/proxy_init:0.8.0-gke.1
      imageID: docker-pullable://gcr.io/gke-release/istio/proxy_init@sha256:ed2b18249fc7cc3fb10f73a29b4b6121bd193b8213460da3658e6d1f51b877ef
  ```

* Determining the ingress IP and port

  ```sh
  kubectl -n istio-system get services istio-ingressgateway
  NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                                      AGE
  istio-ingressgateway   LoadBalancer   10.47.240.38   35.192.144.72   80:31380/TCP,443:31390/TCP,31400:31400/TCP   1d
  ```

  ```sh
  export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  ```

  _(we are using the default port 80 here)_

* Confirm the app is running

  ```sh
  curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
  ```

  or if `hey` is available

  ```sh
  hey -n 200 -c 20 http://${GATEWAY_URL}/productpage
  ```

* Apply default destination rules

  The destination rules is required if you want to use Istio to control the routing by `subsets` (which can be mapped to any labels)

  There destination rules need to be applied before trying out the [intelligent-routing](https://istio.io/docs/examples/intelligent-routing/) exmaple

  * If you did not enable mutual TLS, execute this command:
    ```sh
    kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
    ```
  * If you did enable mutual TLS, execute this command:
    ```sh
    kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
    ```

* What's next
  * [Intelligent routing](https://istio.io/docs/examples/intelligent-routing/)
  * [In-Depth Telemetry](https://istio.io/docs/examples/telemetry/)
  * [TLS Origination for Egress Traffic](https://istio.io/docs/examples/advanced-egress/egress-tls-origination/)
  * [Configure an Egress Gateway](https://istio.io/docs/examples/advanced-egress/egress-gateway/)

## Teardown

* Delete the sample application ([how to](https://istio.io/docs/examples/bookinfo/#uninstall-from-kubernetes-environment))
* Delete the `istio-ingressgateway` ingress service

  ```sh
  kubectl -n istio-system delete service istio-ingressgateway
  ```

* Delete the cluster using the same service account that creates it

  ```sh
  gcloud config set account ${SA}@${PROJECT_ID}.iam.gserviceaccount.com
  ```

  ```sh
  gcloud alpha container clusters delete asuka
  ```

## Further reads

* Disable auto-injection for a namespace

  i.e. You want to spin up some util pods that doesn't want to use istio

  ```sh
  Kustomize build . | kubectl apply -f -
  ```

* View the grafana dashboard

  ```sh
  kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000
  ```

  ```sh
  http://localhost:3000/dashboard/db/istio-dashboard
  http://localhost:3000/dashboard/db/pilot-dashboard
  http://localhost:3000/dashboard/db/mixer-dashboard
  ```

* View the Prometheus console

  ```sh
  kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090
  ```

  ```sh
  http://localhost:9090/graph
  ```