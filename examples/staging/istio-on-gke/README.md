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
cd istio-0.8.0
```

* Add the istioctl client to your PATH

```sh
export PATH=$PATH:$PWD/bin
```

* Deploy the Bookinfo sample application to your cluster.

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

## Clean up

```sh
gcloud container clusters delete asuka
```
