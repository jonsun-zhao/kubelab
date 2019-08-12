# Network Policy

A network policy is a specification of how groups of pods are allowed to communicate with each other and other network endpoints

## key points

- NP is namespaced (not global)
- NP only applies to **pods**
  - it determines how groups of pods are allowed to communicate with each other and other network endpoints
- NP is implemented by network plugin thus `calico` is involved
- Under the hood, NP is enforced by `iptables` on the nodes

## Isolated and Non-isolated Pods

- Pods are non-isolated by default
- Pods are isolated when selected by NP
  - the pod will reject any connections that are not allowed by any ingress/egress rules

## NP resource skeleton

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      ...(pod labels)...
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from: []
    ports: []
  egress:
  - to: []
    ports: []
```

## Spec

- `podSelector`
  - Pods are selected by their `label` via `podSelector`
  - empty `podSelector`, in form of `{}`, selects all pods in the namespace where this NP is created

- `policyTypes`
  - either `Ingress` or `Egress`, or both, indicating if the NP is controlling ingress and/or egress traffic to/from the selected pods
  - If `policyTypes` is omitted when creating the NP, it is set to `Ingress` by default

    ```yaml
    kubectl create -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: default-deny
    EOF
    ```

    ```yaml
    kubectl create -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: default-deny
    spec:
      podSelector: {}
      policyTypes:
      - Ingress
    EOF
    ```

  - `policyTypes` `Egress` is set automatically when the NP is created with any `egress` rules

- `ingress`
  - whitelist rules allows traffic matches `from` and `ports`

- `egress`
  - whitelist rules allows traffic matches `to` and `ports`

## The rule of `from` and `to`

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: alpha
spec:
  podSelector:
    matchLabels:
      run: nginx
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.63.48.0/22
        except:
        - 10.63.48.4/32
    - namespaceSelector:
        matchLabels:
          ns: a
    - podSelector:
        matchLabels:
          run: nginx
    - namespaceSelector:
        matchLabels:
          ns: b
      podSelector:
        matchLabels:
          app: hammer
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8
    ports:
    - protocol: TCP
      port: 80
```

Trick:

- `from` and `to` are YAML arrays
- **OR** between array elements (i.e. from ip block or namespace or pod)
- **AND** between dict elements inside an array elements (i.e. from pod `app:hammer` in namespace `ns:b`)


## Demo

- Create demo namespaces

```sh
k create ns alpha
k create ns beta
k label ns alpha ns=a
k label ns beta ns=b
```

- Create demo pods

```sh
# deploy 2 nginx pods
kubectl run --namespace=alpha nginx --replicas=2 --image=nginx
# expose as clusterIP service
kubectl expose --namespace=alpha deployment nginx --port=80

# create and shell into a test pod
kubectl run --namespace=alpha access --rm -ti --image busybox /bin/sh

/ # wget -q nginx -O -
<!DOCTYPE html>
<html>
...
<h1>Welcome to nginx!</h1>
...
```

- Snapshot the iptables rules

```sh
knodes_iptables-save
> dumping ...

# gke-calico-default-pool-a310cacc-xkcp.1565587467
```

## Enable isolation

```sh
kubectl create -f - <<EOF
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: alpha-deny
  namespace: alpha
spec:
  podSelector:
    matchLabels: {}
EOF
```

- Test Isolation

```sh
/ # wget -q --timeout=5 nginx -O -
wget: download timed out
```

- Snapshot the iptables rules again

```sh
knodes_iptables-save
> dumping ...


# gke-calico-default-pool-a310cacc-xkcp.1565587495
```

- Analyzing the iptables diff

> Follow one of the nginx pod

```sh
→ k -n alpha get pods nginx-dbddb74b8-z9dpn -o json | jq_pod
name=[nginx-dbddb74b8-z9dpn] namespace=[alpha] uid=[220bbe83-bcc1-11e9-8b10-42010a80002c] nodeName=[gke-calico-default-pool-a310cacc-xkcp] podIP=[10.64.1.4] status=[Running]
#container: name=[nginx] image=[nginx:latest] docker://538881baa115c82fb742148715e2601ed8c31ea14c3a596ce6e04ca2070eb435

→ kcontainer_nic nginx-dbddb74b8-z9dpn alpha nginx
node: gke-calico-default-pool-a310cacc-xkcp
nic: cali92d634f8f03
```

```sh
-A FORWARD -m comment --comment "cali:wUHhoiAYhphO9Mso" -j cali-FORWARD
...
-A cali-FORWARD -m comment --comment "cali:vjrMJCRpqwy5oRoX" -j MARK --set-xmark 0x0/0xe0000
-A cali-FORWARD -m comment --comment "cali:A_sPAO0mcxbT9mOV" -m mark --mark 0x0/0x10000 -j cali-from-hep-forward
-A cali-FORWARD -i cali+ -m comment --comment "cali:8ZoYfO5HKXWbB3pk" -j cali-from-wl-dispatch
-A cali-FORWARD -o cali+ -m comment --comment "cali:jdEuaPBe14V2hutn" -j cali-to-wl-dispatch
-A cali-FORWARD -m comment --comment "cali:12bc6HljsMKsmfr-" -j cali-to-hep-forward
-A cali-FORWARD -m comment --comment "cali:MH9kMp5aNICL-Olv" -m comment --comment "Policy explicitly accepted packet." -m mark --mark 0x10000/0x10000 -j ACCEPT
...
-A cali-from-wl-dispatch -i cali92d634f8f03 -m comment --comment "cali:fZm1qoM4zABjSE7o" -g cali-fw-cali92d634f8f03
...
-A cali-fw-cali92d634f8f03 -m comment --comment "cali:4P4KjbB-mrou_chd" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A cali-fw-cali92d634f8f03 -m comment --comment "cali:3vUrh0snPxkIA8rr" -m conntrack --ctstate INVALID -j DROP
-A cali-fw-cali92d634f8f03 -m comment --comment "cali:6bKe6Vcw1LtNpnO-" -j MARK --set-xmark 0x0/0x10000
-A cali-fw-cali92d634f8f03 -m comment --comment "cali:swWUH2vJ4Lg-3cQy" -j cali-pro-kns.alpha
-A cali-fw-cali92d634f8f03 -m comment --comment "cali:1zHafbuM14H1LZI9" -m comment --comment "Return if profile accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-fw-cali92d634f8f03 -m comment --comment "cali:PA1GIl9n0O-XW8U2" -j cali-pro-ksa.alpha.default
-A cali-fw-cali92d634f8f03 -m comment --comment "cali:7PLJ-bT9V4H13OgS" -m comment --comment "Return if profile accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-fw-cali92d634f8f03 -m comment --comment "cali:7sXL_A9wd4Ig6HY_" -m comment --comment "Drop if no profiles matched" -j DROP
...
-A cali-pro-kns.alpha -m comment --comment "cali:_UCrjWldmFR3jSBk" -j MARK --set-xmark 0x10000/0x10000
-A cali-pro-kns.alpha -m comment --comment "cali:R8F0l7IjPYOuy8nG" -m mark --mark 0x10000/0x10000 -j RETURN
...
-A cali-to-wl-dispatch -o cali92d634f8f03 -m comment --comment "cali:cEOQ_ZfhDRO6Wd_B" -g cali-tw-cali92d634f8f03
...
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:FUgB7G5ObIh96acF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:WQJ64LtbzEP_A0C0" -m conntrack --ctstate INVALID -j DROP
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:lq8KVGA-L8Gpp_Q1" -j MARK --set-xmark 0x0/0x10000
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:LFDbDDVQlKjgSqzz" -m comment --comment "Start of policies" -j MARK --set-xmark 0x0/0x20000
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:JQWPRfDgwMpzGD_6" -m mark --mark 0x0/0x20000 -j cali-pi-_kxgQy6VBWOo3Mj1GNsy
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:s2YyMMoOMXsbm10n" -m comment --comment "Return if policy accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:gclo7LawxDosdaHf" -m comment --comment "Drop if no policies passed packet" -m mark --mark 0x0/0x20000 -j DROP
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:BHaQlbZNFFeosqhm" -j cali-pri-kns.alpha
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:upgfCMv9m9Rg-qo8" -m comment --comment "Return if profile accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:QIrbpSaULbttJXmT" -j cali-pri-ksa.alpha.default
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:RPeTChfSvtESEfgn" -m comment --comment "Return if profile accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:ojgehy9_nNPpiyjI" -m comment --comment "Drop if no profiles matched" -j DROP
```

- Allow access using a network policy

```sh
kubectl create -f - <<EOF
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-nginx
  namespace: alpha
spec:
  podSelector:
    matchLabels:
      run: nginx
  ingress:
    - from:
      - podSelector:
          matchLabels:
            run: access
EOF
```

- Snapshot the iptables rules

```sh
knodes_iptables-save
> dumping ...

# gke-calico-default-pool-a310cacc-xkcp.1565590311
```

```sh
...
-A cali-to-wl-dispatch -o cali92d634f8f03 -m comment --comment "cali:cEOQ_ZfhDRO6Wd_B" -g cali-tw-cali92d634f8f03
...
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:FUgB7G5ObIh96acF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:WQJ64LtbzEP_A0C0" -m conntrack --ctstate INVALID -j DROP
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:lq8KVGA-L8Gpp_Q1" -j MARK --set-xmark 0x0/0x10000
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:LFDbDDVQlKjgSqzz" -m comment --comment "Start of policies" -j MARK --set-xmark 0x0/0x20000
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:ODoIaF_IPx3TRmF0" -m mark --mark 0x0/0x20000 -j cali-pi-_e8MLrhOHDfNlfSa51Ak
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:MVOQxoANBbR11zgK" -m comment --comment "Return if policy accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:LkeeeuVbaL4uBlnj" -m mark --mark 0x0/0x20000 -j cali-pi-_kxgQy6VBWOo3Mj1GNsy
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:eoYOE3_IE3Y9cuyP" -m comment --comment "Return if policy accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:DENqw_tUMNBLYcWY" -m comment --comment "Drop if no policies passed packet" -m mark --mark 0x0/0x20000 -j DROP
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:ON2zKuQtJfA4tb10" -j cali-pri-kns.alpha
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:Dh-T8hAFGcEyArmG" -m comment --comment "Return if profile accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:gaIrhBZhebaQy98N" -j cali-pri-ksa.alpha.default
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:CAWiU-725yymw2-w" -m comment --comment "Return if profile accepted" -m mark --mark 0x10000/0x10000 -j RETURN
-A cali-tw-cali92d634f8f03 -m comment --comment "cali:_igYgy60wKudPMD0" -m comment --comment "Drop if no profiles matched" -j DROP
...
-A cali-pi-_e8MLrhOHDfNlfSa51Ak -m comment --comment "cali:sEcu68UJEL6S4gUe" -m set --match-set cali40s:XZEFRy4u2E2Kz28IwtNm0u8 src -j MARK --set-xmark 0x10000/0x10000
-A cali-pi-_e8MLrhOHDfNlfSa51Ak -m comment --comment "cali:ylM9819c6tRAOxVz" -m mark --mark 0x10000/0x10000 -j RETURN
```

[`ipset`](https://www.linuxjournal.com/content/advanced-firewall-configurations-ipset) extension is used to create firewall rules that match entire "sets" of addresses.

```sh
root@gke-calico-default-pool-a310cacc-xkcp:~# ipset list
...

Name: cali40s:XZEFRy4u2E2Kz28IwtNm0u8
Type: hash:net
Revision: 6
Header: family inet hashsize 1024 maxelem 1048576
Size in memory: 408
References: 3
Number of entries: 1
Members:
10.64.1.5
```

```sh
→ k -n alpha get pods -o wide | grep 10.64.1.5
access-56ff88b445-82kg5   1/1     Running   0          67m   10.64.1.5   gke-calico-default-pool-a310cacc-xkcp   <none>
```
