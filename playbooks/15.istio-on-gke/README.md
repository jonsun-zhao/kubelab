# Istio on GKE (beta)

## Deploy the cluster

```sh
gcloud beta container clusters create asuka \
  --machine-type=n1-standard-2 \
  --num-nodes=3 \
  --image-type=COS \
  --cluster-version=1.12 \
  --tags=ssh \
  --addons=Istio,HttpLoadBalancing --istio-config=auth=MTLS_STRICT \
  --preemptible \
  --enable-ip-alias \
  --create-subnetwork "" \
  --scopes default,cloud-platform,cloud-source-repos,service-control
```

## Setup CLI

* Grab the latest Istio bundle

  ```sh
  curl -L https://git.io/getLatestIstio | sh -
  ```

  > Follow the provided instructions to setup the CLI

## Sample applications

* [bookinfo](bookinfo)
* [go-web](go-web)

## Further reads

* View the grafana dashboard

  ```sh
  kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000
  ```

  ```sh
  http://localhost:3000/dashboard/db/istio-dashboard
  http://localhost:3000/dashboard/db/pilot-dashboard
  http://localhost:3000/dashboard/db/mixer-dashboard
  ```

* View the Prometheus console

  ```sh
  kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090
  ```

  ```sh
  http://localhost:9090/graph
  ```