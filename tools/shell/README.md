# Shell Helpers

## Prerequisites

* Download the patched kubectl

```sh
gsutil cp gs://nmiu-play_tools/kubectl-114-darwin /path/to/bin/k-dev
gsutil cp gs://nmiu-play_tools/kubectl-114-linux /path/to/bin/k-dev
chmod +x /path/to/bin/k-dev
```

## Installation

* Source the scripts in `.bashrc` or `.zshrc`

```sh
source /path/to/k8s.sh
```

## Functions

* [current list](func.md)
