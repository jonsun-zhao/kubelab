# Custom Resource Definition (CRD)

## Install helm/tiller

* How to install [helm](https://docs.helm.sh/using_helm/)
* How to install `tiller`

  ```sh
  kubectl apply -f tiller.yaml
  helm init --service-account tiller
  ```
