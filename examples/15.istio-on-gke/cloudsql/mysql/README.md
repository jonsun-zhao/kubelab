# Postgres

## Prerequisites

* Setup a MySQL CloudSQL instance/database `sinatra1`
* Allow workloads in the mesh to reach google domains (required by `cloud_sql_proxy`)

  ```sh
  kubectl apply -f ../egressl_to_google.yaml
  ```

* Allow workloads in the mesh to reach `sinatra1` instance

  ```sh
  kubectl apply -f egress_to_cloudsql.yaml
  ```

## Sidecar

> `cloud_sql_proxy` is deployed as a sidecar

```sh
kubectl apply -f sidecar.yaml
```

## Standalone

> `cloud_sql_proxy` is deployed as a standalone service listening on port `3306`

```sh
kubectl apply -f standalone.yaml
```