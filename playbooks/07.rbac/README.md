# RBAC

## Prerequisites

### Create a Google Group

Group: [nm-k8s-rbac](https://groups.google.com/a/google.com/forum/#!members/nm-k8s-rbac)

### Bind yourself to the `cluster-admin` role

> Note: this is required in GKE version prior to 1.12, as there is an issue in `Cloud IAM` that blocks users, even with the most privileged Cloud IAM role attached, from creating `role` and `clusterrole` in the cluster. GKE v1.12+ fixed it.

```sh
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
```

### Create serviceaccount and pod

```sh
kustomize build . | kubectl apply -f -
```

## Test

### Shell into the pod

```sh
kubectl exec hammer -it bash
```

### Run `kubectl` inside the pod

If `automountServiceAccountToken: false` is removed from the pod spec, the serviceaccount secret will be mounted at the default path `/var/run/secrets/kubernetes.io/serviceaccount` automatically. Running `kubectl` in the pod will just worked as it is smart enough to look for token and CA in the default path.

We specifically mount the serviceaccount secret at `/etc/foo` here, just because we can.

```sh
alias k="kubectl -s https://kubernetes:443 --token=`cat /etc/foo/token` --certificate-authority=/etc/foo/ca.crt"
```

As expected, we cannot list pods as the serviceaccount doesn't have any permissions attached.

```sh
k get pods

Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:client" cannot list pods in the namespace "default": Unknown user "system:serviceaccount:default:client"
```

```sh
k auth can-i list pods

no
```

### Bind the serviceaccount to the `default-reader` role and try again

```sh
kubectl apply -f rolebinding.yaml
```

```sh
k get pods

NAME         READY     STATUS    RESTARTS   AGE
hammer       1/1       Running   0          1h
```

```sh
k auth can-i list pods

yes
```

### Impersonate

`kubectl` supports impersonation when accessing the API. `--as` and/or `--as-group` can be used for such impersonation.

* list pods as a different user

```sh
kubectl get pods --as=jaw@google.com

Error from server (Forbidden): pods is forbidden: User "jaw@google.com" cannot list pods in the namespace "default": Required "container.pods.list" permission.
```

* Add `jaw@google.com` to Google group `nm-k8s-rbac@google.com` and try again

This works because the group is bounded to the `default-reader` role already.

```sh
kubectl get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com
NAME         READY     STATUS    RESTARTS   AGE
hammer       1/1       Running   0          4h
```

_kube-apiserver log:_

```console
2018-07-06 15:27:40.000 AEST
&{nmiu@google.com [system:authenticated] map[]} is acting as &{jaw@google.com [nm-k8s-rbac@google.com] map[]}
```

#### Impersonate in the pod

* list pods as Google group `nm-k8s-rbac@google.com`

Impersonation failed because the pod's serviceaccount does not have the privilege to *impersonate* another user or group.

```sh
k get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com

Error from server (Forbidden): users "jaw@google.com" is forbidden: User "system:serviceaccount:default:client" cannot impersonate users at the cluster scope: Unknown user "system:serviceaccount:default:client"
```

* Bind the serviceaccount to the `cluster-impersonater` role and try again

```sh
kubectl apply -f impersonate.yaml
```

```sh
k get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com

NAME         READY     STATUS    RESTARTS   AGE
hammer       1/1       Running   0          4h
```

_kube-apiserver log:_

```console
2018-07-06 15:33:19.000 AEST
&{system:serviceaccount:default:client acdb4d24-80da-11e8-846c-42010a800153 [system:serviceaccounts system:serviceaccounts:default system:authenticated] map[]} is acting as &{jaw@google.com [nm-k8s-rbac@google.com] map[]}
```

## Teardown

```sh
kubectl delete -f impersonate.yaml
kubectl delete -f rolebinding.yaml
kustomize build . | kubectl delete -f -
```
