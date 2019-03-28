# Istio + CloudSQL

kubectl -n istio-workload create secret generic cloudsql-instance-credentials --from-file=cloudsqlclient.json
