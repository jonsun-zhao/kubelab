# App: sample-controller

> [source and doc](https://github.com/neoseele/sample-controller)

## Build the image

* build with Cloud Builder

  ```sh
  make build
  ```

* build locally

  ```sh
  make build-local
  ```

## Deploy in K8s

```sh
kubectl apply -f k8s/controller.yaml
```

## Run demo

```sh
kubectl apply -f k8s/app.yaml
```
