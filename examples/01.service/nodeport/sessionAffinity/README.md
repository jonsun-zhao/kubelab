# Session Affinity

GKE supports `ClientIP` type `sessionAffinity` in k8s Service object.

`sessionAffinity` is implemented by `iptables` (via [recent](http://ipset.netfilter.org/iptables-extensions.man.html#lbBW) module) in GKE, as proxy-mode `iptables` is the only mode used in GKE (details of proxy modes can be seen [here](https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies))

In the example we created, we scale the php-apache deployment to 4 pods. 2 of them is running on node `gke-asuka-default-pool-3d65e6a8-kbb1`

```sh
kubectl get pods -o wide
NAME                              READY     STATUS    RESTARTS   AGE       IP          NODE
php-apache-dep-58bc5f5b77-8rdlz   1/1       Running   0          8m        10.28.8.5   gke-asuka-default-pool-3d65e6a8-kbb1
php-apache-dep-58bc5f5b77-jwxqs   1/1       Running   0          34m       10.28.6.5   gke-asuka-default-pool-731ddb85-sw18
php-apache-dep-58bc5f5b77-ph7vs   1/1       Running   0          8m        10.28.8.6   gke-asuka-default-pool-3d65e6a8-kbb1
php-apache-dep-58bc5f5b77-vp4hj   1/1       Running   0          25m       10.28.7.6   gke-asuka-default-pool-6bb7cbe5-2wmb
```

The pods are selected by this service

```sh
kubectl get service | grep php-apache-svc
php-apache-svc   NodePort    10.31.240.99   <none>        80:31332/TCP,443:30558/TCP   1h
```

By looking at the NAT table on the node `gke-asuka-default-pool-3d65e6a8-kbb1` in iptable, we can learnt that:

1. an external client's packet arrived on `nodePort` 31332 will be routed to one of the 2 pods which are currently running on the node. (because we are using `externalTrafficPolicy: Local` here)
2. `iptables` picks the pod randomly and remembers the decision it made for this client
3. any subsequent packets `iptables` recieved from the same client will be routed to the same pod
4. an internal client's packet (usually from a pod) targeting the service VIP `10.31.240.99` will be routed to anyone of the 4 pods randomly
5. `iptables` marks and remembers the routing decision for internal traffic as well

```sh
# iptables -t nat -S | grep '"default/php-apache-svc:http"'

-A KUBE-NODEPORTS -p tcp -m comment --comment "default/php-apache-svc:http" -m tcp --dport 31332 -j KUBE-XLB-TLHPL6Z5YI33DALW

-A KUBE-SEP-IYELN4HVX6HRBXNW -s 10.28.8.6/32 -m comment --comment "default/php-apache-svc:http" -j KUBE-MARK-MASQ
-A KUBE-SEP-IYELN4HVX6HRBXNW -p tcp -m comment --comment "default/php-apache-svc:http" -m recent --set --name KUBE-SEP-IYELN4HVX6HRBXNW --mask 255.255.255.255 --rsource -m tcp -j DNAT --to-destination 10.28.8.6:80
-A KUBE-SEP-L7T7MUF6AEBEWCCN -s 10.28.6.5/32 -m comment --comment "default/php-apache-svc:http" -j KUBE-MARK-MASQ
-A KUBE-SEP-L7T7MUF6AEBEWCCN -p tcp -m comment --comment "default/php-apache-svc:http" -m recent --set --name KUBE-SEP-L7T7MUF6AEBEWCCN --mask 255.255.255.255 --rsource -m tcp -j DNAT --to-destination 10.28.6.5:80
-A KUBE-SEP-LRDQVXAG5PE7TSRT -s 10.28.7.6/32 -m comment --comment "default/php-apache-svc:http" -j KUBE-MARK-MASQ
-A KUBE-SEP-LRDQVXAG5PE7TSRT -p tcp -m comment --comment "default/php-apache-svc:http" -m recent --set --name KUBE-SEP-LRDQVXAG5PE7TSRT --mask 255.255.255.255 --rsource -m tcp -j DNAT --to-destination 10.28.7.6:80
-A KUBE-SEP-SGFKGWTTGOP4QXUH -s 10.28.8.5/32 -m comment --comment "default/php-apache-svc:http" -j KUBE-MARK-MASQ
-A KUBE-SEP-SGFKGWTTGOP4QXUH -p tcp -m comment --comment "default/php-apache-svc:http" -m recent --set --name KUBE-SEP-SGFKGWTTGOP4QXUH --mask 255.255.255.255 --rsource -m tcp -j DNAT --to-destination 10.28.8.5:80

-A KUBE-SERVICES ! -s 10.28.0.0/14 -d 10.31.240.99/32 -p tcp -m comment --comment "default/php-apache-svc:http cluster IP" -m tcp --dport 80 -j KUBE-MARK-MASQ
-A KUBE-SERVICES -d 10.31.240.99/32 -p tcp -m comment --comment "default/php-apache-svc:http cluster IP" -m tcp --dport 80 -j KUBE-SVC-TLHPL6Z5YI33DALW

-A KUBE-SVC-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m recent --rcheck --seconds 10800 --reap --name KUBE-SEP-L7T7MUF6AEBEWCCN --mask 255.255.255.255 --rsource -j KUBE-SEP-L7T7MUF6AEBEWCCN
-A KUBE-SVC-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m recent --rcheck --seconds 10800 --reap --name KUBE-SEP-LRDQVXAG5PE7TSRT --mask 255.255.255.255 --rsource -j KUBE-SEP-LRDQVXAG5PE7TSRT
-A KUBE-SVC-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m recent --rcheck --seconds 10800 --reap --name KUBE-SEP-SGFKGWTTGOP4QXUH --mask 255.255.255.255 --rsource -j KUBE-SEP-SGFKGWTTGOP4QXUH
-A KUBE-SVC-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m recent --rcheck --seconds 10800 --reap --name KUBE-SEP-IYELN4HVX6HRBXNW --mask 255.255.255.255 --rsource -j KUBE-SEP-IYELN4HVX6HRBXNW

-A KUBE-SVC-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m statistic --mode random --probability 0.25000000000 -j KUBE-SEP-L7T7MUF6AEBEWCCN
-A KUBE-SVC-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m statistic --mode random --probability 0.33332999982 -j KUBE-SEP-LRDQVXAG5PE7TSRT
-A KUBE-SVC-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-SGFKGWTTGOP4QXUH
-A KUBE-SVC-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -j KUBE-SEP-IYELN4HVX6HRBXNW

-A KUBE-XLB-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m recent --rcheck --seconds 10800 --reap --name KUBE-SEP-SGFKGWTTGOP4QXUH --mask 255.255.255.255 --rsource -j KUBE-SEP-SGFKGWTTGOP4QXUH
-A KUBE-XLB-TLHPL6Z5YI33DALW -m comment --comment "default/php-apache-svc:http" -m recent --rcheck --seconds 10800 --reap --name KUBE-SEP-IYELN4HVX6HRBXNW --mask 255.255.255.255 --rsource -j KUBE-SEP-IYELN4HVX6HRBXNW
-A KUBE-XLB-TLHPL6Z5YI33DALW -m comment --comment "Balancing rule 0 for default/php-apache-svc:http" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-SGFKGWTTGOP4QXUH
-A KUBE-XLB-TLHPL6Z5YI33DALW -m comment --comment "Balancing rule 1 for default/php-apache-svc:http" -j KUBE-SEP-IYELN4HVX6HRBXNW

```