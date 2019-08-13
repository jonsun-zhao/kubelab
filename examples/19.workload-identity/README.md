# Workload Identify

[Doc](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)

## Limitation

- Workload Identity is available for clusters running GKE version 1.12 and higher.
- Workload Identity replaces the need to use `Metadata Concealment` and as such, the two approaches are **incompatible**. The sensitive metadata protected by Metadata Concealment is also protected by Workload Identity.
- When Workload Identity is enabled, you can no longer use the Compute Engine default service account. To learn more, refer to the alternatives section below

## Enable Workload Identity

### Create a new cluster

```sh
gcloud beta container clusters create ikari \
    --machine-type=n1-standard-2 \
    --num-nodes=2 \
    --image-type=COS \
    --cluster-version=1.12 \
    --tags=ssh \
    --preemptible \
    --enable-ip-alias \
    --create-subnetwork "" \
    --identity-namespace=nmiu-play.svc.id.goog
```

### Create a test service account

```sh
export GSA=gke-test-sa
gcloud iam service-accounts create $GSA
export GSA_EMAIL=`gcloud iam service-accounts list --format='value(email)' --filter="name:${GSA}"`
```

### Bind permissions to the test service account

```sh
export PROJECT=`gcloud config get-value project`

gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$GSA_EMAIL \
  --role roles/container.developer
```

### Create K8 service account

```sh
kubectl create serviceaccount hammer -n default
```

### Allow KSA to use GSA

```sh
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:nmiu-play.svc.id.goog[default/hammer]" \
  gke-test-sa@nmiu-play.iam.gserviceaccount.com
```

### Add the `iam.gke.io/gcp-service-account=[GSA_NAME]@[PROJECT_NAME]` annotation to the Kubernetes service account, using the email address of the Google service account

```sh
kubectl annotate serviceaccount \
  --namespace default \
  hammer \
  iam.gke.io/gcp-service-account=gke-test-sa@nmiu-play.iam.gserviceaccount.com
```

### Verify the service accounts are configured correctly by creating a Pod with the Kubernetes service account that runs the cloud-sdk container image, and connecting to it with an interactive session

```sh
kubectl run -it \
  --generator=run-pod/v1 \
  --image google/cloud-sdk \
  --serviceaccount hammer \
  --namespace default \
  workload-identity-test
```

You are now connected to an interactive shell within the created Pod. Run the following command:

```sh
gcloud auth list
```

## Cleaning up

### Revoke access to the Google service account

```sh
gcloud iam service-accounts remove-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:nmiu-play.svc.id.goog[default/hammer]" \
  gke-test-sa@nmiu-play.iam.gserviceaccount.com
```

It can take up to 30 minutes for cached tokens to expire. You can check whether the cached tokens have expired with this command:

```sh
gcloud auth list
```

The cached tokens have exprired if the output of that command no longer includes `gke-test-sa@nmiu-play.iam.gserviceaccount.com`.

Disable Workload Identity in the cluster:

```sh
gcloud beta container clusters update rei --disable-workload-identity
```
