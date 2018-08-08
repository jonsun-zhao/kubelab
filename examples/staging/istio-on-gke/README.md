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
--cluster-version=1.10.5-gke.3 \
--tags=ssh \
--addons=Istio --istio-config=auth=MUTUAL_TLS \
--preemptible \
--scopes default,cloud-platform,cloud-source-repos,service-control
```

### Option 2

Enabling Istio **without** security when creating a cluster

```sh
gcloud alpha container clusters create asuka \
--machine-type=n1-standard-2 \
--num-nodes=3 \
--image-type=COS \
--cluster-version=1.10.5-gke.3 \
--tags=ssh \
--addons=Istio --istio-config=auth=None \
--preemptible \
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
```

* Inspected the auto-injected sidecars from a pod

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

* (optional) Disable auto-injection for a namespace

i.e. You want to spin up some util pods that doesn't want to use istio

```sh
Kustomize build . | kubectl apply -f -
```

* More complex [examples](https://istio.io/docs/examples/)

## Clean up

```sh
gcloud container clusters delete asuka
```
