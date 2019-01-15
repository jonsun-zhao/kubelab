# Hey

## Explaination

[hey](https://github.com/rakyll/hey/blob/master/README.md) is essentially a http load runner.

In the example, we are using a containerized `hey` in a Kubernetes CronJob to send some load a user-defined web application.

2 `hey` parameters are exposed and configurable via `secret` and `configMap`

* target web app's `url` (default: *http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token*) is defined in `hey-secret`
* `requests` (default: *100*) and `concurrent_requests` (default: *10*) are defined in `hey-config`

## Deploy

```sh
kubectl apply -f hey.yaml

configmap "hey-config" created
secret "hey-secret" created
cronjob "hey" created
```

## Verify

```sh
kubectl get cronjob
NAME      SCHEDULE      SUSPEND   ACTIVE    LAST SCHEDULE   AGE
hey       */1 * * * *   False     0         33s             5m

kubectl get job
NAME             DESIRED   SUCCESSFUL   AGE
hey-1533216840   1         1            2m
hey-1533216900   1         1            1m
hey-1533216960   1         1            31s

kubectl get pods -a
NAME                   READY     STATUS      RESTARTS   AGE
hey-1533216840-4vwrt   0/1       Completed   0          2m
hey-1533216900-xwdg8   0/1       Completed   0          1m
hey-1533216960-kpmvp   0/1       Completed   0          39s

kubectl logs hey-1533216960-kpmvp
Summary:
  Total:	0.3315 secs
  Slowest:	0.0577 secs
  Fastest:	0.0208 secs
  Average:	0.0306 secs
  Requests/sec:	301.6618


Response time histogram:
  0.021 [1]	|■
  0.024 [14]	|■■■■■■■■■■■■■■■■■■
  0.028 [28]	|■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.032 [31]	|■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.036 [9]	|■■■■■■■■■■■■
  0.039 [3]	|■■■■
  0.043 [4]	|■■■■■
  0.047 [4]	|■■■■■
  0.050 [5]	|■■■■■■
  0.054 [0]	|
  0.058 [1]	|■


Latency distribution:
  10% in 0.0239 secs
  25% in 0.0261 secs
  50% in 0.0288 secs
  75% in 0.0324 secs
  90% in 0.0430 secs
  95% in 0.0473 secs
  99% in 0.0577 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0017 secs, 0.0208 secs, 0.0577 secs
  DNS-lookup:	0.0016 secs, 0.0000 secs, 0.0174 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0002 secs
  resp wait:	0.0286 secs, 0.0205 secs, 0.0414 secs
  resp read:	0.0003 secs, 0.0002 secs, 0.0012 secs

Status code distribution:
  [200]	100 responses
```

## Customize

### Change the URL

* Option 1

  Update `url` in the `hey-secret` manually

  ```sh
  echo http://www.google.com | base64
  ```

* Option 2

  ```sh
  kubectl create secret generic hey-secret --from-literal=url=http://www.google.com -o yaml --dry-run | kubectl replace -f -
  ```

### Change parameters

You may change the hey parameters in the `hey-secret` and/or `hey-config` to suit your needs

* Option 1

  Manually update the parameters in the `hey.yaml` and re-run the deploy command

* Option 2

  ```sh
  kubectl create configmap hey-config --from-literal=requests=200 --from-literal=concurrent_requests=20 -o yaml --dry-run | kubectl replace -f -
  ```

### Change other hey parameters

([all hey parameters](https://github.com/rakyll/hey#usage))

Manually update the `command` section

```sh
  command:
  - "/bin/sh"
  - "-c"
  - '/hey -n $REQUESTS -c $CONCURRENT_REQUESTS -H "Metadata-Flavor:Google" $URL'
```

## Teardown

```sh
kubectl delete -f hey.yaml
```