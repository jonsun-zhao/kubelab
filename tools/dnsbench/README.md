# DNS Bench

A simple DNS server benchmarking tool developed by [these guys](https://github.com/AskMediaGroup/dnsbench)

> The code here is nothing but some cloudbuild configs

## Cheat

```sh
gsutil cp gs://nmiu-play_tools/dnsbench-linux /path/to/your/bin
gsutil cp gs://nmiu-play_tools/dnsbench-darwin /path/to/your/bin
```

## Build your own

  > NOTE: Please adjust the `_GOOS_` in `cloudbuild.yaml` to suit your own environment (Linux vs Mac)

  * Build with Cloud Build

    ```sh
    make build
    ```

  * Build Locally

    > NOTE: Requires [`cloud-build-local`](https://cloud.google.com/cloud-build/docs/build-debug-locally)

    ```sh
    make build-local
    ```

## Retrieve the Binary

  * Cloud Build

    > NOTE: Please adjust the `_BUCKET_NAME_` in `cloudbuild.yaml` to suit your needs

    ```sh
    gsutil cp gs://nmiu-play_tools/dnsbench-$_GOOS_ /path/to/your/bin
    ```

  * Local

    > NOTE: `workspace` default to `/tmp/dnsbench_build`. Adjustable in the `Makefile`

    ```sh
    cp /tmp/dnsbench_build/bin/dnsbench-$_GOOS_ /path/to/you/bin
    ```

## Clean up

> Removes the workspace directory used by `cloud-build-local`

```sh
make clean-local
```