# App: sample-controller

## Build the image

* build with Cloud Builder

  ```sh
  make build
  ```

* build locally

  ```sh
  make build-local
  ```

## Clean up

```sh
docker stop my-go-web && docker rm my-go-web
docker rmi go-web:local
```
