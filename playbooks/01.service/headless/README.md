# Headless Service

Sometimes you don’t need a IP for a service. In this case, you can create `headless` services by specifying `None` for the cluster IP (`.spec.clusterIP`).

This option allows developers to reduce coupling to the Kubernetes system by allowing them freedom to do discovery in their own way. Applications can still use a self-registration pattern and adapters for other discovery systems could easily be built upon this API.

For such Services, a cluster IP is not allocated, kube-proxy does not handle these services, and there is no load balancing or proxying done by the platform for them. How DNS is automatically configured depends on whether the service has selectors defined.

## See it in action

* Service

```sh
kubectl get service php-apache-svc -o yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"php-apache-svc","namespace":"default"},"spec":{"clusterIP":"None","ports":[{"name":"http","port":80,"protocol":"TCP","targetPort":80},{"name":"https","port":443,"protocol":"TCP","targetPort":443}],"selector":{"app":"php-apache"},"type":"ClusterIP"}}
  creationTimestamp: 2018-08-21T02:39:20Z
  name: php-apache-svc
  namespace: default
  resourceVersion: "217633"
  selfLink: /api/v1/namespaces/default/services/php-apache-svc
  uid: 68434885-a4eb-11e8-be97-42010a800142
spec:
  clusterIP: None
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  - name: https
    port: 443
    protocol: TCP
    targetPort: 443
  selector:
    app: php-apache
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```

* Selected Pods

```sh
# kubectl get pods -o wide
NAME                              READY     STATUS    RESTARTS   AGE       IP           NODE
php-apache-dep-58bc5f5b77-kt4gt   1/1       Running   0          18m       10.28.5.15   gke-asuka-default-pool-3d65e6a8-kbb1
php-apache-dep-58bc5f5b77-xjwm5   1/1       Running   0          18m       10.28.3.13   gke-asuka-default-pool-731ddb85-sw18
```

* Service FQDN

```sh
[root@hammer ~]# dig php-apache-svc.default.svc.cluster.local.
...
;; QUESTION SECTION:
;php-apache-svc.default.svc.cluster.local. IN A

;; ANSWER SECTION:
php-apache-svc.default.svc.cluster.local. 30 IN	A 10.28.3.13
php-apache-svc.default.svc.cluster.local. 30 IN	A 10.28.5.15
```
