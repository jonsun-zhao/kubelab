# ISTIO with PSP

## Issue

When creating Istio on GKE with PSP enabled

```sh
gcloud beta container clusters create asuka \
  --machine-type=n1-standard-2 \
  --num-nodes=3 \
  --image-type=COS \
  --cluster-version=1.11 \
  --tags=ssh \
  --preemptible \
  --enable-ip-alias \
  --create-subnetwork "" \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=3 \
  --enable-stackdriver-kubernetes \
  --enable-pod-security-policy \
  --enable-network-policy \
  --metadata disable-legacy-endpoints=true \
  --workload-metadata-from-node=SECURE \
  --service-account=my-cluster-admin@nmiu-play.iam.gserviceaccount.com \
  --addons=Istio,HttpLoadBalancing --istio-config=auth=MTLS_STRICT
```

It seems the `istio-xxx-service-account` are not associated with any PSP policies by default.

As a result, istio infrastructure pods are unable to start

```sh
→ ki get event -o json | jq -r '.items[]| select(.message|test(".forbidden.")) | [.metadata.name, .message] | @tsv'
istio-citadel-776fb85794.157a93105e351df5       Error creating: pods "istio-citadel-776fb85794-" is forbidden: unable to validate against any pod security policy: []
istio-cleanup-secrets.157a93105dc61d6b  Error creating: pods "istio-cleanup-secrets-" is forbidden: unable to validate against any pod security policy: []
istio-egressgateway-56d5d887c6.157a93105f9bf133 Error creating: pods "istio-egressgateway-56d5d887c6-" is forbidden: unable to validate against any pod security policy: []
istio-galley-794f98cf5f.157a93105c11f324        Error creating: pods "istio-galley-794f98cf5f-" is forbidden: unable to validate against any pod security policy: []
istio-ingressgateway-7bd7fd57bf.157a931070a1e24a        Error creating: pods "istio-ingressgateway-7bd7fd57bf-" is forbidden: unable to validate against any pod security policy: []
istio-pilot-548b59dc84.157a93106c575bda Error creating: pods "istio-pilot-548b59dc84-" is forbidden: unable to validate against any pod security policy: []
istio-policy-6c9ff6b54f.157a93105f5c3ccd        Error creating: pods "istio-policy-6c9ff6b54f-" is forbidden: unable to validate against any pod security policy: []
istio-security-post-install.157a93106287d0a9    Error creating: pods "istio-security-post-install-" is forbidden: unable to validate against any pod security policy: []
istio-sidecar-injector-f555db659.157a931071e2ce48       Error creating: pods "istio-sidecar-injector-f555db659-" is forbidden: unable to validate against any pod security policy: []
istio-telemetry-74c57cf98d.157a93106019cb48     Error creating: pods "istio-telemetry-74c57cf98d-" is forbidden: unable to validate against any pod security policy: []
prometheus-7c589d4989.157a93105f42ae94  Error creating: pods "prometheus-7c589d4989-" is forbidden: unable to validate against any pod security policy: []
```

## Workaround

The easiest way to solve this is attach all the `istio-xxx-service-account` to the `gce.privileged` via a clusterrolebinding.

```sh
kubectl apply -f psp.yaml
```