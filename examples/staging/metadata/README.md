# Metadata concealment

metadata concealment can only be enabled when:

* creating a new cluster
* adding a new node pool to an existing cluster.

## Prerequisites

### Create the service account for nodes with minimal permissions

* create the service account

```sh
export NODE_SA_NAME=gke-node-sa
gcloud iam service-accounts create $NODE_SA_NAME --display-name "Node Service Account"
export NODE_SA_EMAIL=`gcloud iam service-accounts list --format='value(email)' \
  --filter='displayName:Node Service Account'`
```

* bind minimal permissions to the service account

```sh
export PROJECT=`gcloud config get-value project`

gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$NODE_SA_EMAIL \
  --role roles/monitoring.metricWriter
gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$NODE_SA_EMAIL \
  --role roles/monitoring.viewer
gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$NODE_SA_EMAIL \
  --role roles/logging.logWriter
gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$NODE_SA_EMAIL \
  --role roles/storage.objectViewer
```

* create the cluster

```sh
gcloud beta container clusters create asuka \
--machine-type=n1-standard-2 \
--num-nodes=2 \
--image-type=COS \
--cluster-version=1.11 \
--tags=ssh \
--preemptible \
--enable-ip-alias \
--create-subnetwork "" \
--enable-autoscaling \
--min-nodes=1 \
--max-nodes=3 \
--enable-stackdriver-kubernetes \
--workload-metadata-from-node=SECURE \
--service-account=my-cluster-admin@nmiu-play.iam.gserviceaccount.com \
--metadata disable-legacy-endpoints=true
```

## Observation

* A new NAT rule is created to capture traffics to `169.254.169.254:80` and redirect them to `127.0.0.1:988` (metadata-proxy)

```sh
Chain PREROUTING (policy ACCEPT 14 packets, 1229 bytes)
 pkts bytes target     prot opt in     out     source               destination
11508  955K KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
  391 23460 DNAT       tcp  --  *      *       0.0.0.0/0            169.254.169.254      tcp dpt:80 /* metadata-concealment: bridge traffic to metadata server goes to metadata proxy */ to:127.0.0.1:988
    3   184 KUBE-HOSTPORTS  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube hostport portals */ ADDRTYPE match dst-type LOCAL
```
