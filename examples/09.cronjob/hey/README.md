# Hey

## Explaination

[hey](https://github.com/rakyll/hey/blob/master/README.md) is essentially a http load runner.

In the example, we are using a containerized `hey` in a Kubernetes CronJob to send some load a user-defined web application.

2 `hey` parameters are exposed and configurable via `secret` and `configMap`

* target web app's `url` (default: *http://www.google.com*) is defined in `hey-secret`
* `requests` (default: *100*) and `concurrent_requests` (default: *10*) are defined in `hey-config`

## Deploy

```sh
kubectl apply -f hey.yaml
```

## Customize

You may change the hey parameters in the `hey-secret` and/or `hey-config` to suit your needs

Options:

* Manually update the parameters in the `hey.yaml` and re-run the deploy command
* Update the k8s objects directly via `kubectl`

  ```sh
  kubectl create configmap hey-config --from-literal=requests=200 --from-literal=concurrent_requests=20 -o yaml --dry-run | kubectl replace -f -
  kubectl create secret generic hey-secret --from-literal=url=http://www.redhat.com -o yaml --dry-run | kubectl replace -f -
  ```

## Teardown

```sh
kubectl delete -f hey.yaml
```

**sample logs when the job is running**

```sh
Summary:
  Total:	2.1563 secs
  Slowest:	0.3299 secs
  Fastest:	0.1744 secs
  Average:	0.2075 secs
  Requests/sec:	46.3749


Response time histogram:
  0.174 [1]	|■
  0.190 [54]	|■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.206 [14]	|■■■■■■■■■■
  0.221 [10]	|■■■■■■■
  0.237 [8]	|■■■■■■
  0.252 [1]	|■
  0.268 [0]	|
  0.283 [1]	|■
  0.299 [1]	|■
  0.314 [0]	|
  0.330 [10]	|■■■■■■■


Latency distribution:
  10% in 0.1788 secs
  25% in 0.1809 secs
  50% in 0.1859 secs
  75% in 0.2131 secs
  90% in 0.3145 secs
  95% in 0.3253 secs
  99% in 0.3299 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0129 secs, 0.1744 secs, 0.3299 secs
  DNS-lookup:	0.0014 secs, 0.0000 secs, 0.0153 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0004 secs
  resp wait:	0.1857 secs, 0.1665 secs, 0.2771 secs
  resp read:	0.0087 secs, 0.0062 secs, 0.0173 secs

Status code distribution:
  [200]	100 responses
```