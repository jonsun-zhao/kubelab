# App: go-web

## Build the image

* build with Cloud Builder

  ```sh
  make build
  ```

* build locally

  ```sh
  make build-local
  ```

## Run the app locally

```sh
docker run --rm -d -p 8000:8000 -p 10443:10443 --name my-go-web go-web:local
```

## Clean up

```sh
docker stop my-go-web && docker rm my-go-web
docker rmi go-web:local
```

## Rest APIs

* `GET /`
* `GET /error`
* `GET /health`
* `GET /liveness`
* `GET /readiness`
* `GET /ping`

* `/stress`
  * `GET /stress/cpu`
  * `GET /stress/cpu?load=0.1&duration=10`
  > load: push cpu load to 0.1; duration: keep the cpu load for 10 seconds
  * `GET /stress/memory`
  * `GET /stress/memory?size=100`
  > size: allocate memroy in MB

* `/dns`
  * `GET /dns/weight?=1000`
  > weight: number of concurrent dns queries in each web request

* `/people`
  * `GET /people`
  * `GET /people/{id}`
  * `POST /people/{id}`
  * `PUT /people/{id}`
  * `DELETE /people/{id}`
  > sample rest API

* `/kubedump`