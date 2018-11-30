# Pod Security Policy

## Create a cluster with PSP enabled

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
--enable-pod-security-policy
```

## View the predefined PSPs

```sh
kubectl get psp
NAME                           DATA      CAPS      SELINUX    RUNASUSER   FSGROUP    SUPGROUP   READONLYROOTFS   VOLUMES
gce.event-exporter             false               RunAsAny   RunAsAny    RunAsAny   RunAsAny   false            hostPath,secret
gce.fluentd-gcp                false               RunAsAny   RunAsAny    RunAsAny   RunAsAny   false            configMap,hostPath,secret
gce.persistent-volume-binder   false               RunAsAny   RunAsAny    RunAsAny   RunAsAny   false            nfs,secret
gce.privileged                 true      *         RunAsAny   RunAsAny    RunAsAny   RunAsAny   false            *
gce.unprivileged-addon         false               RunAsAny   RunAsAny    RunAsAny   RunAsAny   false            emptyDir,configMap,secret
```

## Create deployment `php-apahce`

```sh
kubectl apply -f deployment.yaml
```

You may noticed that the deployment is created but none of the pod is created, even your user account can `use` the most privileged PSP.

`kubectl get event` is showing errors like this:

```sh
1s          11s          12        php-apache-dep-6c5475744d.156bc3f2f16c028b              ReplicaSet               Warning   FailedCreate              replicaset-controller                                  Error creating: pods "php-apache-dep-6c5475744d-" is forbidden: unable to validate against any pod security policy: []
```

```sh
kubectl auth can-i use podsecuritypolicies/gce.privileged
yes
```

This is because pods managed by deployment/replicaset are created via the controller manager. Granting the controller access to the policy would grant access for all pods created by that the controller, so the preferred method for authorizing policies is to grant access to the pod’s service account.

## Create RBAC resources

> Note: One need to grant the current user the `cluster-admin` role so the new ClusterRole can be created

```sh
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
```

```sh
kubectl apply -f rbac.yaml
```

The following resources are created:

* ServiceAccount `client`
* ClusterRole `psp-test` with the role of `use` the PSP of `podsecuritypolicies/gce.privileged`
* ClusterRoleBinding `psp-test` which binds SC `client` to ClusterRole `psp-test`

## Modify the deployment to use the ServiceAccount `client` to run the pods

```sh
kubectl edit deployment php-apache-dep
```

```yaml
...
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: php-apache
    spec:
      serviceAccountName: client  <----- add this
      containers:
      - image: gcr.io/nmiu-play/php-apache
        imagePullPolicy: Always
        name: php-apache
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
...
```

```sh
deployment.extensions "php-apache-dep" edited
```

`php-apache-xxx` pods should be created since then.

## Tear down

```sh
kubectl delete -f deployment.yaml
kubectl delete -f rbac.yaml
gcloud container clusters delete asuka
```