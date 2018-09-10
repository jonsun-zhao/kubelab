# cert-manager

[[upstream doc](https://cert-manager.readthedocs.io/en/latest/)]

cert-manager is a native Kubernetes certificate management controller. It can help with issuing certificates from a variety of sources, such as Let’s Encrypt, HashiCorp Vault, a simple signing keypair, or self signed.

It will ensure certificates are valid and up to date, and attempt to renew certificates at a configured time before expiry.

It is loosely based upon the work of kube-lego and has borrowed some wisdom from other similar projects e.g. kube-cert-manager.

![overview](overview.png)

**cert-manager** is a nice and easy example to show how `CRD` is used.

## Installation

* [prerequisites](../README.md)

```sh
helm install \
  --name cert-manager \
  --namespace kube-system \
  stable/cert-manager
```

## What the created CRDs looks like

* `certificates.certmanager.k8s.io`
* `clusterissuers.certmanager.k8s.io`
* `issuers.certmanager.k8s.io`

```sh
kubectl -n kube-system get crd certificates.certmanager.k8s.io -o yaml
```

```yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  labels:
    app: cert-manager
    chart: cert-manager-v0.4.1
    heritage: Tiller
    release: cert-manager
  name: certificates.certmanager.k8s.io
  ...
spec:
  group: certmanager.k8s.io
  names:
    kind: Certificate
    listKind: CertificateList
    plural: certificates
    shortNames:
    - cert
    - certs
    singular: certificate
  scope: Namespaced
  version: v1alpha1
```

```sh
kubectl -n kube-system get crd issuers.certmanager.k8s.io -o yaml
```

```yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  labels:
    app: cert-manager
    chart: cert-manager-v0.4.1
    heritage: Tiller
    release: cert-manager
  name: issuers.certmanager.k8s.io
  ...
spec:
  group: certmanager.k8s.io
  names:
    kind: Issuer
    listKind: IssuerList
    plural: issuers
    singular: issuer
  scope: Namespaced
  version: v1alpha1
```

```sh
kubectl -n kube-system get crd clusterissuers.certmanager.k8s.io -o yaml
```

```yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  labels:
    app: cert-manager
    chart: cert-manager-v0.4.1
    heritage: Tiller
    release: cert-manager
  name: clusterissuers.certmanager.k8s.io
  ...
spec:
  group: certmanager.k8s.io
  names:
    kind: ClusterIssuer
    listKind: ClusterIssuerList
    plural: clusterissuers
    singular: clusterissuer
  scope: Cluster
  version: v1alpha1
```