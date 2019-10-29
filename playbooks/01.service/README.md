# Service

> Examples are created with helm chart `fortio`

## Prerequesites

```sh
cd charts/fortio
```

## Playbooks

* [clusterip](clusterip)
  * Service with type `ClusterIP`
  * It creates a in-cluster virtual load balancer (a.k.a VIP) which directs traffics to the selected `Pods`

```sh
# expose via ClusterIP service
keel_run -r dev -f playbooks/values-svc.yaml -a -- \
  --set service.type=ClusterIP
```

* [headless](headless)
  * Service with type `ClusterIP` and the `clustlerIP` is set to `None`
  * It does not create any in-cluster VIP
  * It creates a DNS `A` record of IPs of **all** the selected Pods

```sh
# expose via headless service
keel_run -r dev -f playbooks/values-svc.yaml -a -- \
  --set service.headless.enabled=true
```

* [nodeport](nodeport)
  * Service with type `NodePort`
  * It creates a in-cluster virtual load balancer (same as `ClusterIP`)
  * It also expose the selected `Pods` on the nodes at a static high port.
    * all nodes in the cluster will listen on this static port if `externalTrafficPolicy` is set to `Cluster`
    * only the nodes that runs the selected Pods will listen on this static port if `externalTrafficPolicy` is set to `Local`

```sh
# expose via NodePort service
keel_run -r dev -f playbooks/values-svc.yaml -a -- \
  --set service.type=NodePort
```

* [network-lb](network-lb)
  * Service with type `LoadBalancer`
  * It does all the things the `NodePort` type service does
  * It also creates a GCP Network Load Balancer (L4) which directs traffic to the static `NodePort` opened on the nodes

```sh
# expose via lb service
keel_run -r dev -f playbooks/values-svc.yaml -a
```

* [internal-lb](internal-lb)
  * Service with type `LoadBalancer` and the annotation of `cloud.google.com/load-balancer-type: internal`
  * It is almost identical to [network-lb](network-lb)
  * The only difference is that the GCP Load Balancer it creates is a internal one

```sh
# expose via ilb service
keel_run -r dev -f playbooks/values-svc.yaml -a -- \
  --set service.ilb.enabled=true
```
