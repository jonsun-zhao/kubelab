# Pod with FileStore

## Prerequisites

### Create filestore instance and share

```sh
gcloud beta filestore instances create fs01 \
  --project=nmiu-play \
  --location=us-central1-a \
  --tier=STANDARD \
  --file-share=name="nfs01",capacity=2TB \
  --network=name="default"
```

### Create storage object

* fetch the filestore name and ip

  ```sh
  gcloud beta filestore instances describe fs01 \
    --location us-central1-a --format json | jq '
      {
        path: ("/"+.fileShares[0].name),
        server: (.networks[0].ipAddresses[0])
      }
    '
  {
    "path": "/nfs01",
    "server": "10.126.188.26"
  }
  ```

* update [storage.yaml](storage.yaml) accordingly

## Usage

* preview

```sh
kustomize build .
```

* deploy

```sh
kustomize build . | kubectl apply -f -
```

* teardown

```sh
kustomize build . | kubectl delete -f -
```
