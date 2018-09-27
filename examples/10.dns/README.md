# Configure stub-domain and upstream DNS servers

## Prerequisites

### Scale down the GKE cluster to one node

_so that it is easier to sniff packets from pod and node_

## Explaination

the following `ConfigMap` sets up a DNS configuration with a single stub domain and two upstream nameservers.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"acme.local": ["1.2.3.4"]}
  upstreamNameservers: |
    ["8.8.8.8", "8.8.4.4"]
```

As specified, DNS requests with the `.acme.local` suffix are forwarded to a DNS listening at `1.2.3.4`. Google Public DNS serves the upstream queries.

### Impacts on Pods

Custom upstream nameservers and stub domains won’t impact Pods that have their `dnsPolicy` set to `Default` or `None`.

If a Pod’s `dnsPolicy` is set to `ClusterFirst`, its name resolution is handled differently, depending on whether stub-domain and upstream DNS servers are configured.

#### Without custom configurations

Any query that does not match the configured cluster domain suffix, such as “www.kubernetes.io”, is forwarded to the upstream nameserver inherited from the node.

#### With custom configurations

If stub domains and upstream DNS servers are configured (as in the previous example), DNS queries will be routed according to the following flow:

* The query is first sent to the DNS caching layer in `kube-dns`.
* From the caching layer (`dnsmasq`), the suffix of the request is examined and then forwarded to the appropriate DNS, based on the following cases:
  * Names with the cluster suffix (e.g.`.cluster.local`): The request is sent to kube-dns.
  * Names with the stub domain suffix (e.g. `.acme.local`): The request is sent to the configured custom DNS resolver (e.g. listening at `1.2.3.4`).
  * Names without a matching suffix (e.g.`widget.com`): The request is forwarded to the upstream DNS (e.g. Google public DNS servers at `8.8.8.8` and `8.8.4.4`).

![Graph](https://d33wubrfki0l68.cloudfront.net/340889cb80e81dcd19a16bc34697a7907e2b229a/24ad0/docs/tasks/administer-cluster/dns-custom-nameservers/dns.png)

## Deploy

```sh
kustomize build . | kubectl apply -f -
```

## Test

The test pod's dnsPolicy is set to `ClusterFirst`. Do the following to verify the DNS resolution is delegated to the upstream DNS.

* Log into the test pod and run `dig www.google.com`
* Log into the node where the pod is scheduled, run tcpdump in `toolbox`

```sh
$ toolbox
20180123-00: Pulling from google-containers/toolbox
f49cf87b52c1: Pull complete
...
Press ^] three times within 1s to kill container.
# tcpdump -nn port 53
...
05:15:14.178028 IP 10.128.0.9.57624 > 8.8.4.4.53: 44903+ [1au] A? www.google.com. (43)
05:15:14.178332 IP 10.128.0.9.57624 > 8.8.8.8.53: 44903+ [1au] A? www.google.com. (43)
05:15:14.179879 IP 8.8.8.8.53 > 10.128.0.9.57624: 44903 6/0/1 A 74.125.124.105, A 74.125.124.99, A 74.125.124.147, A 74.125.124.104, A 74.125.124.106, A 74.125.124.103 (139)
05:15:14.180093 IP 8.8.4.4.53 > 10.128.0.9.57624: 44903 6/0/1 A 209.85.145.147, A 209.85.145.103, A 209.85.145.106, A 209.85.145.105, A 209.85.145.104, A 209.85.145.99 (139)
```

  > DNS query for `www.google.com` sent directly to `8.8.8.8` and `8.8.4.4`

* Reverse the ConfigMap

```sh
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
EOF
```

* Re-run the dig on the test pod

```sh
...
05:17:08.991803 IP 10.44.0.13.34775 > 10.47.240.10.53: 45476+ [1au] A? www.redhat.com. (43)
05:17:26.791805 IP 10.128.0.9.62244 > 169.254.169.254.53: 569+ [1au] A? www.redhat.com. (43)
05:17:26.967877 IP 169.254.169.254.53 > 10.128.0.9.62244: 569 4/0/1 CNAME ds-www.redhat.com.edgekey.net., CNAME ds-www.redhat.com.edgekey.net.globalredir.akadns.net., CNAME e3396.dscx.akamaiedge.net., A 23.61.177.74 (201)
...
```

  > `tcpdump` output indicated that `www.google.com` is resolved by metadata server (`169.254.169.254`) now.

## Teardown

```sh
kustomize build . | kubectl delete -f -
```