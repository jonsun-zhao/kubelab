# Local SSD Alpha

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
export CLOUDSDK_CONTAINER_USE_V1_API_CLIENT=false
```

or

```sh
gcloud config set container/use_v1_api_client false
```

### Check if alpha api is woriing

```sh
gcloud alpha container clusters list --log-http
```

* [reference](https://cloud.google.com/kubernetes-engine/docs/reference/api-organization#beta)


## Setup

```sh
gcloud alpha container clusters create asuka \
--machine-type=n1-standard-1 \
--num-nodes=2 \
--image-type=COS \
--cluster-version=1.10.5-gke.2 \
--tags=ssh \
--enable-kubernetes-alpha \
--local-ssd-volumes count=1,type=scsi,format=block \
--preemptible \
--scopes default,cloud-platform,cloud-source-repos,service-control
```

_unset use_v1_api_client_ 
```sh
gcloud config unset container/use_v1_api_client
```

## Clean up

```sh
gcloud container clusters delete asuka
```
