# Service

## Examples

* [clusterip](clusterip)
  * Service with type `ClusterIP`
  * It creates a in-cluster virtual load balancer which directs traffics to the selected `Pods`
* [nodeport](nodeport)
  * Service with type `NodePort`
  * It creates a in-cluster virtual load balancer (same as `ClusterIP`)
  * It also expose the selected `Pods` on the nodes at a static high port.
    * all nodes in the cluster will listen on this static port if `externalTrafficPolicy` is set to `Cluster`
    * only the nodes that runs the selected Pods will listen on this static port if `externalTrafficPolicy` is set to `Local` 
* [network-lb](network-lb)
  * Service with type `LoadBalancer`
  * It does all the things the `NodePort` type service does
  * It also creates a GCP Network Load Balancer (L4) which directs traffic to the static `NodePort` opened on the nodes
* [internal-lb](internal-lb)
  * Service with type `LoadBalancer` and the annotation of `cloud.google.com/load-balancer-type: internal`
  * It is almost identical to [network-lb](network-lb)
  * The only difference is that the GCP Load Balancer it creates is a internal one

## Usage

```sh
cd clusterip
```

* preview

```sh
kustomize build .
```

* deploy

```sh
kustomize build . | kubectl apply -f -
```

* teardown

```sh
kustomize build . | kubectl delete -f -
```