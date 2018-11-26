# Pod Security Policy

```sh
gcloud beta container clusters create asuka \
--machine-type=n1-standard-2 \
--num-nodes=3 \
--image-type=COS_CONTAINERD \
--cluster-version=1.11 \
--tags=ssh \
--preemptible \
--enable-ip-alias \
--create-subnetwork "" \
--enable-autoscaling \
--min-nodes=2 \
--max-nodes=4 \
--scopes default,cloud-platform,cloud-source-repos,service-control \
--enable-stackdriver-kubernetes \
--enable-pod-security-policy \
--enable-network-policy
```