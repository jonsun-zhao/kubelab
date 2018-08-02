# Pod with GCE PD

## Prerequisites

### Create a Persistent Disk named `test-disk` and format it as `ext4`

* create the disk

```sh
gcloud compute disks create test-disk --zone us-central1-a --size 2g
```

* attach the PD to a Linux VM to format it as `ext4`

```sh
mkfs.ext4 /dev/sdb
```

* add a `index.php` to the disk

```php
<?php

echo "Hello from PD!\n";
```

## Usage

* dry-run

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
