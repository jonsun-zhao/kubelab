# Creating a simple CA based issuer

## Generate a signing key pair

```sh
COMMON_NAME=premium-cloud-support.com

# Generate a CA private key
openssl genrsa -out ca.key 2048

# Create a self signed Certificate, valid for 10yrs with the 'signing' option set
openssl req -x509 -new -nodes -key ca.key -subj "/CN=${COMMON_NAME}" -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt
```

## Save the signing key pair as a Secret

```sh
kubectl create secret tls ca-key-pair \
   --cert=ca.crt \
   --key=ca.key \
   --namespace=default
```

## Create Issuer

```sh
kubectl apply -f issuer.yaml
```

## Create Certificate

```sh
kubectl apply -f cert.yaml
```