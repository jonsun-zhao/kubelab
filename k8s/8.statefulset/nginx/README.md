# StatefulSet

## Deploy

```sh
kubectl apply -f nginx.yaml

service "nginx-statefulset-svc" created
statefulset "web" created
```

* Verify the Pods and PVCs

```sh
kubectl get pod

NAME      READY     STATUS    RESTARTS   AGE
web-0     1/1       Running   0          1h
web-1     1/1       Running   0          1h
web-2     1/1       Running   0          17m

kubectl get pvc

NAME        STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
www-web-0   Bound     pvc-5da4001a-939c-11e8-8e7e-42010a8000e0   11G        RWO            standard       1h
www-web-1   Bound     pvc-d7e29c80-939c-11e8-8e7e-42010a8000e0   11G        RWO            standard       1h
www-web-2   Bound     pvc-7c5b0e4c-93a5-11e8-8e7e-42010a8000e0   11G        RWO            standard       17m
```

* Confirm that different index page is served from the service IP

```sh
kubectl get service

NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
kubernetes              ClusterIP      10.47.240.1     <none>            443/TCP        2d
nginx-statefulset-svc   LoadBalancer   10.47.252.128   104.197.172.177   80:31501/TCP   1h
```

```sh
for i in {0..9}; do curl http://104.197.172.177; done

web-2
web-2
web-0
web-2
web-0
web-1
web-2
web-0
web-1
web-0
```

## Teardown

### Delete the stateful app

```sh
kubectl delete -f nginx.yaml
```