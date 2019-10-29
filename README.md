# KubeLab

A repository of Kubernetes sample workloads and tools

This is a living repo that grows with the K8s releases.

## Author

Neil Miao <nmiu@google.com>

## Repo structure

* [tools](tools)
  > tools and apps that are used in the playbooks

* [charts](charts)
  > helm charts that are used in the playbooks

* [playbooks](playbooks)
  > playbooks to showcase k8s features and usecases
  * `/\d+\.[\S-]+/` - GA playbooks
    * [list](playbooks.md)
  * `staging` - work-in-progress
