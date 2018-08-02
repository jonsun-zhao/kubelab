(https://istio.io/docs/setup/kubernetes/quick-start.html)

```sh
gcloud beta container clusters create kube-istio \
--zone=us-central1-b \
--machine-type=n1-standard-1 \
--num-nodes=3 \
--node-labels=istio=true \
--tags=ssh \
--scopes cloud-platform,storage-rw,logging-write,monitoring-write,service-control,service-management
```

Grant cluster admin permissions to the current user (admin permissions are required to create the necessary RBAC rules for Istio):

```sh
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
```

```sh
cd ~/tools
curl -L https://git.io/getLatestIstio | sh -
cd ~/tools/istio-0.2.9
```

Install Istio’s core components. Choose one of the two mutually exclusive options below:

a) Install Istio without enabling mutual TLS authentication between sidecars. Choose this option for clusters with existing applications, applications where services with an Istio sidecar need to be able to communicate with other non-Istio Kubernetes services, and applications that use liveliness and readiness probes, headless services, or StatefulSets.

```sh
kubectl apply -f install/kubernetes/istio.yaml
```

b) Install Istio and enable mutual TLS authentication between sidecars.:

```sh
kubectl apply -f install/kubernetes/istio-auth.yaml
kubectl apply -f install/kubernetes/istio-initializer.yaml
```

Load the test app

```sh
cd ~/projs/nmiu-play/gke/istio

istioctl kube-inject -f php.yaml -o php-istio.yaml

cd ~/tools/istio-0.2.9/install/kubernetes/addons

kubectl apply -f zipkin-to-stackdriver.yaml
```
