# RBAC

## Prerequisites

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

## Bind the current user to `cluster-admin` role

> Otherwise `kubectl apply -f nginx-ingress-controller.yaml` will complain about unable to create cluster roles and bindings

```sh
cat << EOF | kubectl apply -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-admin-binding
subjects:
- kind: User
  name: `gcloud config get-value account`
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

## Setup

### Create service account and the pod

_not automounting the service account's secret_


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

### Create a pod reader role and bind the service account `client` to this role

```sh
kubectl apply -f rolebinding.yaml
```

### Try again

```sh
# within the pod
k get pods

NAME         READY     STATUS    RESTARTS   AGE
nm-toolbox   1/1       Running   0          1h
```

```sh
# within the pod
k auth can-i list pods

yes
```

### Impersonate

```sh
kubectl get pods --as=jaw@google.com

Error from server (Forbidden): pods is forbidden: User "jaw@google.com" cannot list pods in the namespace "default": Required "container.pods.list" permission.
```

[Create a test Group](https://groups.google.com/a/google.com/forum/#!members/nm-k8s-rbac)

```sh
kubectl get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com
NAME         READY     STATUS    RESTARTS   AGE
nm-toolbox   1/1       Running   0          4h
```
> _kube-apiserver log:_
```
2018-07-06 15:27:40.000 AEST
&{nmiu@google.com [system:authenticated] map[]} is acting as &{jaw@google.com [nm-k8s-rbac@google.com] map[]}
```

#### Impersonate in the test pod

```sh
# within the pod
k get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com

Error from server (Forbidden): users "jaw@google.com" is forbidden: User "system:serviceaccount:default:client" cannot impersonate users at the cluster scope: Unknown user "system:serviceaccount:default:client"
```

```sh
kubectl apply -f impersonate.yaml
```

```sh
# within the pod
k get pods --as=jaw@google.com --as-group=nm-k8s-rbac@google.com

NAME         READY     STATUS    RESTARTS   AGE
nm-toolbox   1/1       Running   0          4h
```

> _kube-apiserver log:_
```
2018-07-06 15:33:19.000 AEST
&{system:serviceaccount:default:client acdb4d24-80da-11e8-846c-42010a800153 [system:serviceaccounts system:serviceaccounts:default system:authenticated] map[]} is acting as &{jaw@google.com [nm-k8s-rbac@google.com] map[]}
```

## Clean up

```sh
gcloud container clusters delete asuka
```
