# Nginx StatefulSet with Local-Volume

## Prerequisites

### Create a GKE cluster with local-SSD attached

```sh
gcloud beta container clusters create asuka \
--machine-type=n1-standard-2 \
--num-nodes=3 \
--image-type=COS \
--cluster-version=1.10.5-gke.4 \
--tags=ssh \
--local-ssd-count=1 \
--preemptible \
--enable-stackdriver-kubernetes \
--scopes default,cloud-platform,cloud-source-repos,service-control
```

### Bind the current user to `cluster-admin` role

> Otherwise `kubectl apply -f nginx-ingress-controller.yaml` will complain about unable to create cluster roles and bindings

```sh
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
```

## Deploy the `local-volume-provisioner`

```sh
kubectl apply -f local-volume-provisioner.yaml

configmap "local-provisioner-config" created
daemonset "local-volume-provisioner" created
serviceaccount "local-storage-admin" created
clusterrolebinding "local-storage-provisioner-pv-binding" created
clusterrole "local-storage-provisioner-node-clusterrole" created
clusterrolebinding "local-storage-provisioner-node-binding" created
storageclass "fast-disks" created
```

* List the auto-created PVs

```sh
kubectl get pv

NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM     STORAGECLASS   REASON    AGE
local-pv-4ece48cb   368Gi      RWO            Delete           Available             fast-disks               43s
local-pv-af96daf3   368Gi      RWO            Delete           Available             fast-disks               1m
local-pv-ccbad648   368Gi      RWO            Delete           Available             fast-disks               1m
```

## Deploy a stateful app to use the local PVs

```sh
kustomize build . | kubectl apply -f -

service "nginx-statefulset-svc" created
statefulset "web" created
```

* Verify the Pods and PVCs

_notice the age of the Pods and PVCs, they are created in order_

```sh
kubectl get pod

NAME      READY     STATUS    RESTARTS   AGE
web-0     1/1       Running   0          22s
web-1     1/1       Running   0          14s
web-2     1/1       Running   0          7s

kubectl get pvc

NAME        STATUS    VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
www-web-0   Bound     local-pv-ccbad648   368Gi      RWO            fast-disks     28s
www-web-1   Bound     local-pv-af96daf3   368Gi      RWO            fast-disks     20s
www-web-2   Bound     local-pv-4ece48cb   368Gi      RWO            fast-disks     13s
```

* Confirm that different index page is served from the service IP

```sh
kubectl get service

NAME                    TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
kubernetes              ClusterIP      10.47.240.1    <none>         443/TCP        31m
nginx-statefulset-svc   LoadBalancer   10.47.247.75   35.193.37.76   80:31117/TCP   17m
```

```sh
for i in {0..9}; do curl http://35.193.37.76; done

web-2
web-2
web-0
web-2
web-0
web-1
web-2
web-0
web-1
web-0
```

## Teardown

### Delete the stateful app

```sh
kustomize build . | kubectl delete -f -
```

### Delete the PVCs

```sh
for i in 0 1 2; do k delete pvc www-web-${i}; done
persistentvolumeclaim "www-web-0" deleted
persistentvolumeclaim "www-web-1" deleted
persistentvolumeclaim "www-web-2" deleted
```

### Verify the PVs are released

```sh
kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM               STORAGECLASS   REASON    AGE
local-pv-4ece48cb   368Gi      RWO            Delete           Released    default/www-web-2   fast-disks               45m
local-pv-ccbad648   368Gi      RWO            Delete           Available                       fast-disks               0s
```

```sh
kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM     STORAGECLASS   REASON    AGE
local-pv-4ece48cb   368Gi      RWO            Delete           Available             fast-disks               4s
local-pv-af96daf3   368Gi      RWO            Delete           Available             fast-disks               12s
local-pv-ccbad648   368Gi      RWO            Delete           Available             fast-disks               15s
```

### Remove the `local-volume-provisioner`

```sh
kubectl delete -f local-volume-provisioner.yaml
```

### Delete the cluster

```sh
gcloud container clusters delete asuka
```