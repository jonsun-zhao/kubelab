## Build the image

```sh
make build
```

## Run the app

```sh
PROJECT_ID=`gcloud config get-value project`
gcloud docker -- run -d -p 8000:8000 --name my-go-web gcr.io/$PROJECT_ID/go-web
```

## Clean up

```sh
docker stop my-go-web && docker rm my-go-web
docker rmi gcr.io/$PROJECT_ID/go-web
```

## Rest APIs

* `GET /`
* `GET /error`
* `GET /health`
* `GET /liveness`
* `GET /readiness`

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