#!/bin/sh

if [ "$#" -lt 3 ]; then
  echo "Usage: `basename $0` SECRET_NAME NAMESPACE COMMON_NAME"
  exit 1
fi

name=$1
ns=$2
cn=$3

kubectl get secret -n $ns | grep -q $name

if [ $? -ne 0 ]; then
  openssl req -x509 -newkey rsa:2048 -subj "/C=US/ST=California/L=San Francisco/O=CPS/CN=${cn}" -keyout tls.key -out tls.crt -days 3650 -nodes -sha256
  kubectl -n $ns create secret tls $name --cert tls.crt --key tls.key
fi
