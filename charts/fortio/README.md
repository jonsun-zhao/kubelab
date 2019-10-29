# Fortio

## Prerequisite

> Only needed when `nginx-ingress-controller` is used

```sh
# add nginx repo to helm
helm repo add stable https://kubernetes-charts.storage.googleapis.com/

# update helm repo
helm repo update

# install dependencies
helm dep update
```

## RBAC

> Note: the following `ClusterRoleBinding` is needed if the `kubernetes engine admin` IAM role is **NOT** granted to your account

```sh
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
```

## Deploy

```sh
# create the deployment only
keel_run -r dev -a

# create the deployment
# expose via service
keel_run -r dev -f examples/values-svc.yaml -a

# create the deployment
# expose via service
# backed by pvc
keel_run -r dev -f examples/values-svc-pvc.yaml -a

# create the deployment
# expose via ingress
keel_run -r dev -f examples/values-ing.yaml -a

# create the deployment
# expose via nginx-ingress
keel_run -r dev -f examples/values-ing-nginx.yaml -a

# create the deployment
# expose via ingress with IAP
#
# manual adjustment required:
# - enabling IAP for GKE (https://cloud.google.com/iap/docs/enabling-kubernetes-howto)
# - create a k8s secret consist of client_id and client_secret
# - set ingress.iap.existingSecret to the secret name in values-ing.yaml
# - set ingress.host to suit your need
keel_run -r dev -f examples/values-iap.yaml -a
```

## Clean up

> substitute `-a` with `-d`
