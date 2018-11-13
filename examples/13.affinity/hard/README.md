# Affinity and Anti-Affinity

## Prerequisites

* create a 3 node cluster

## Test

* Create deployment `php-apache` with **2** replicas

```sh
kustomize build . | kubectl apply -f -
```

* Label the node where the `php-apache` pod is **not** running

```sh
kubectl get nodes
NAME                                   STATUS    ROLES     AGE       VERSION
gke-asuka-default-pool-4a759325-5lms   Ready     <none>    23h       v1.10.6-gke.2
gke-asuka-default-pool-4a759325-c5c4   Ready     <none>    23h       v1.10.6-gke.2
gke-asuka-default-pool-4a759325-q793   Ready     <none>    23h       v1.10.6-gke.2
```

```sh
kubectl -o wide get pods
NAME                             READY     STATUS    RESTARTS   AGE       IP            NODE
php-apache-dep-9cb885cf4-gh2hs   1/1       Running   0          2h        10.60.11.14   gke-asuka-default-pool-4a759325-c5c4
php-apache-dep-9cb885cf4-lvsdc   1/1       Running   0          2h        10.60.10.12   gke-asuka-default-pool-4a759325-5lms
```

*label the node with `test=no-pause`*

```sh
kubectl label node gke-asuka-default-pool-4a759325-q793 test=no-pause
```

```sh
k get nodes --show-labels | grep no-pause
gke-asuka-default-pool-4a759325-q793   Ready     <none>    1h        v1.10.6-gke.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/fluentd-ds-ready=true,beta.kubernetes.io/instance-type=n1-standard-2,beta.kubernetes.io/os=linux,cloud.google.com/gke-nodepool=default-pool,cloud.google.com/gke-preemptible=true,failure-domain.beta.kubernetes.io/region=australia-southeast1,failure-domain.beta.kubernetes.io/zone=australia-southeast1-a,kubernetes.io/hostname=gke-asuka-default-pool-4a759325-q793,test=no-pause
```

* Create the pause pod and see it stuck in pending

```sh
kubectl apply -f pause.yaml
```

```sh
kubectl -o wide get pods
NAME                             READY     STATUS    RESTARTS   AGE       IP          NODE
pause                            0/1       Pending   0          3s        <none>      <none>
php-apache-dep-9cb885cf4-gh2hs   1/1       Running   0          3h        10.60.1.7   gke-asuka-default-pool-4a759325-c5c4
php-apache-dep-9cb885cf4-lvsdc   1/1       Running   0          3h        10.60.0.5   gke-asuka-default-pool-4a759325-5lms
```

* Kill one of the `php-apache` and watch
  * all three pods are running now
  * `pause` pod is running on a different node
  * the new `php-apache` pod started on a node where none of the other pods are running

```sh
kubectl -o wide get pods
NAME                             READY     STATUS    RESTARTS   AGE       IP           NODE
pause                            1/1       Running   0          2m        10.60.0.12   gke-asuka-default-pool-4a759325-5lms
php-apache-dep-9cb885cf4-gh2hs   1/1       Running   0          3h        10.60.1.7    gke-asuka-default-pool-4a759325-c5c4
php-apache-dep-9cb885cf4-jhltm   1/1       Running   0          1m        10.60.2.12   gke-asuka-default-pool-4a759325-q793
```

## Teardown

```sh
kubectl delete -f pause.yaml
kustomize build . | kubectl delete -f -
```
