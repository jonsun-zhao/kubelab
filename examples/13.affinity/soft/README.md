# Affinity and Anti-Affinity

## Prerequisites

* create a 3 node cluster

## Test

* Deploy the `pause` pod

```sh
kubectl apply -f pause.yaml
```

* Create deployment `php-apache` with **3** replicas

```sh
kustomize build . | kubectl apply -f -
```

**notice no `php-apache` pods lives on the node where `pause` lives**

```sh
kubectl -o wide get pods
NAME                              READY     STATUS    RESTARTS   AGE       IP           NODE
pause                             1/1       Running   0          4m        10.60.1.13   gke-asuka-default-pool-4a759325-c5c4
php-apache-dep-6ccc58bbc6-dtzp4   1/1       Running   0          14s       10.60.0.15   gke-asuka-default-pool-4a759325-5lms
php-apache-dep-6ccc58bbc6-vf72d   1/1       Running   0          14s       10.60.2.15   gke-asuka-default-pool-4a759325-q793
php-apache-dep-6ccc58bbc6-xtxh4   1/1       Running   0          14s       10.60.2.16   gke-asuka-default-pool-4a759325-q793
```

## Teardown

```sh
kubectl delete -f pause.yaml
kustomize build . | kubectl delete -f -
```
