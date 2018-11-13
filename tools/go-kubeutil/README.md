# go-kubeutil

A simple tool to dump and examine k8s objects from your current k8s cluster 

```sh
kubectl config current-context
gke_XXX
```

## Build the binary

> Please use your own GCS bucket for `_BUCKET_NAME_` in `cloudbuild.yaml`

```sh
make build
```

## Installation

```sh
cd ~/bin
gsutil cp gs://[YOUR_BUCKET]/go-kubeutil .
chmod +x go-kubeutil
```

## Usage

### Dump k8s objects

```sh
$ go-kubeutil dump -h

NAME:
   go-kubeutil dump - dump all k8s objects as JSON files from the current-context

USAGE:
   go-kubeutil dump [command options] [arguments...]

OPTIONS:
   --compress, -z              Compress the output directory
   --pii                       [Caution] Dump secres
   --bucket BUCKET, -b BUCKET  Upload compressed output to GCS BUCKET
   --service-account JSON      [Optional] Load service-account credential from JSON
```

* Fetch the tarball from the Cloud Shell instance (if `go-kubeutil dump` was run on the Cloud Shell)

  ```sh
  gcloud alpha cloud-shell scp --recurse cloudshell:~/xxx.tar.gz localhost:.
  ```

### Examine the k8s objects

> cd into the directory created by the `go-kubeutil dump` command

```sh
$ go-kubeutil get -h

NAME:
   go-kubeutil get - get object from dump

USAGE:
   go-kubeutil get command [command options] [arguments...]

COMMANDS:
     namespace, ns, namespaces     get namespace
     pod, po, pods                 get pod
     node, no, nodes               get node
     service, svc, services        get service
     ingress, ing                  get ingress
     deployment, dep, deployments  get deployment

OPTIONS:
   --help, -h  show help
```

```sh
$ go-kubeutil get pod -h

NAME:
   go-kubeutil get pod - get pod

USAGE:
   go-kubeutil get pod [command options] [arguments...]

OPTIONS:
   --uid UID                                                         get pod(s) by UID
   --namespace NAMESPACE, -n NAMESPACE                               get pod(s) by NAMESPACE
   --label LABEL, -l LABEL                                           get pod(s) by LABEL
   --node NODE                                                       get pod(s) by NODE
   --service SERVICE                                                 get pod(s) by SERVICE
   --ready [true|false]                                              get pod(s) by readiness [true|false]
   --output [wide|yaml|json|v|vv|vvv], -o [wide|yaml|json|v|vv|vvv]  output format [wide|yaml|json|v|vv|vvv]
```
