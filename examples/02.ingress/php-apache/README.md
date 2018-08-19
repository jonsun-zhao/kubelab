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

Service created with above annotation/field will end up having 2 nodePorts:

* One for the actual service: `nodePort`
* The other for the health check: `healthCheckNodePort`
  * user can specified `healthCheckNodePort` when creating the service (auto-allocated if not specified)
  * when the pod is not running on the node, curl to `healthCheckNodePort` returns 503

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

## Notice

For a **Ingress** targeting such service, the `UHC` probes the backend `k8s-be-xxx` on the application serving `nodePort`, **NOT** the `healthCheckNodePort`.

## Execise

* Extend the example by adding the following `readinessProbe` to the container `php-apache`

  ```sh
  readinessProbe:
    httpGet:
      path: /
      port: 80
      scheme: HTTP
    initialDelaySeconds: 90
    timeoutSeconds: 5
    periodSeconds: 5
    successThreshold: 1
    failureThreshold: 3
  ```

* Expose the `php-apache` deployment via Network Load Balancer instead of HTTP Load Balancer