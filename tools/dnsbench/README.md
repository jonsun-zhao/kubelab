# DNS Bench

A simple DNS server benchmarking tool developed by [these guys](https://github.com/AskMediaGroup/dnsbench)

> The code here is nothing but some cloudbuild configs

## Build

  * Build with Cloud Build

    ```sh
    make build
    ```

  * Build Locally

    > Requires [`cloud-build-local`](https://cloud.google.com/cloud-build/docs/build-debug-locally)

    ```sh
    make build-local
    ```

## Clean up

> Remove the workspace directory used by `cloud-build-local`

```sh
make clean-local
```