# RBAC

## Prerequisites

### Create a GKE cluster

```sh
gcloud container clusters create asuka \
--machine-type=n1-standard-1 \
--num-nodes=2 \
--image-type=COS \
--cluster-version=1.10.5-gke.3 \
--tags=ssh \
--preemptible \
--scopes default,cloud-platform,cloud-source-repos,service-control
```

### Create a Google Group

[Test Group](https://groups.google.com/a/google.com/forum/#!members/nm-k8s-rbac)

### Bind the current user to `cluster-admin` role

> Otherwise `kubectl apply -f nginx-ingress-controller.yaml` will complain about unable to create cluster roles and bindings

```sh
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
```

## Test

### Create a service account and a test pod

```sh
kustomize build . | kubectl apply -f -
```

### Try kubectl in the test pod

```sh
kubectl exec toolbox -it bash
```

```sh
# within the pod
alias k="kubectl -s https://kubernetes:443 --token=`cat /etc/foo/token` --certificate-authority=/etc/foo/ca.crt"
```

```sh
# within the pod
k get pods

Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:client" cannot list pods in the namespace "default": Unknown user "system:serviceaccount:default:client"
```

```sh
# within the pod
k auth can-i list pods

no - Unknown user "system:serviceaccount:default:client"
```

### Bind the service account to the pod reader role and try again

```sh
kubectl apply -f rolebinding.yaml
```

```sh
# within the pod
k get pods

NAME         READY     STATUS    RESTARTS   AGE
toolbox      1/1       Running   0          1h
```

```sh
# within the pod
k auth can-i list pods

yes
```

### Impersonate

* Try to get pods as a different user

```sh
kubectl get pods --as=jaw@google.com

Error from server (Forbidden): pods is forbidden: User "jaw@google.com" cannot list pods in the namespace "default": Required "container.pods.list" permission.
```

* Add `jaw@google.com` to group `nm-k8s-rbac@google.com` and try again

```sh
kubectl get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com
NAME         READY     STATUS    RESTARTS   AGE
toolbox      1/1       Running   0          4h
```

_kube-apiserver log:_

```console
2018-07-06 15:27:40.000 AEST
&{nmiu@google.com [system:authenticated] map[]} is acting as &{jaw@google.com [nm-k8s-rbac@google.com] map[]}
```

#### Impersonate in the test pod

* Try to get pods as group `nm-k8s-rbac@google.com`

```sh
# within the pod
k get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com

Error from server (Forbidden): users "jaw@google.com" is forbidden: User "system:serviceaccount:default:client" cannot impersonate users at the cluster scope: Unknown user "system:serviceaccount:default:client"
```

* Bind the service account to the impersonater role and try again

```sh
kubectl apply -f impersonate.yaml
```

```sh
# within the pod
k get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com

NAME         READY     STATUS    RESTARTS   AGE
toolbox      1/1       Running   0          4h
```

_kube-apiserver log:_

```console
2018-07-06 15:33:19.000 AEST
&{system:serviceaccount:default:client acdb4d24-80da-11e8-846c-42010a800153 [system:serviceaccounts system:serviceaccounts:default system:authenticated] map[]} is acting as &{jaw@google.com [nm-k8s-rbac@google.com] map[]}
```

## Teardown

```sh
gcloud container clusters delete asuka
```
