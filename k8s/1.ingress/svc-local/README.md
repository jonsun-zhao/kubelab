# Preserving the client source IP

## Annotation (<1.7)

```yaml
service.beta.kubernetes.io/external-traffic: [OnlyLocal|Global]
service.beta.kubernetes.io/healthcheck-nodeport: 31313
```

## Field (1.7+)

```yaml
service.spec.externalTrafficPolicy: [Local|Cluster]
service.spec.healthCheckNodePort: 31313
```

Service created with above annotation/field will end up having 2 nodeports:

* One for the actual service
* The other for the health check
  * healthcheck-nodeport can be specified (auto-allocated if not specified)
  * when the pod is not running on the node, curl to healthcheck-nodeport returns 503

```sh
$ curl -Is http://10.128.0.2:31313
HTTP/1.1 503 Service Unavailable
Content-Type: application/json
Date: Wed, 16 Aug 2017 12:58:17 GMT
Content-Length: 101

$ curl http://10.128.0.2:31313
{
  "service": {
    "namespace": "kube-system",
    "name": "nginx-ingress-lb"
  },
  "localEndpoints": 0
}
```

When creating a ingress from this service, the http health **k8s-be-xxx** probes the
**service-nodeport**, instead of the healthcheck-nodeport.
