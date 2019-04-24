# Istio + CloudSQL

Tests the `cloud_sql_proxy` functionality in a Istio mesh

## Prerequisites

* a service account for accessing the CloudSQL instance [(doc)](https://cloud.google.com/sql/docs/mysql/connect-external-app#4_if_required_by_your_authentication_method_create_a_service_account)
* a clean GKE Cluster

```sh
→ gcloud beta container clusters create asuka \
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
  --scopes default,cloud-platform,cloud-source-repos,service-control
```

## Deploy

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

```sh
kubectl -n istio-workload create secret generic cloudsql-instance-credentials --from-file=/path/to/cloudsqlclient.json
```

## Examples

* [standalone-all](standalone-all.yaml)
* [sidecar-mysql](sidecar-mysql.yaml)
* [sidecar-postgres](sidecar-postgres.yaml)
