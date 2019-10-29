# GPU

([Upstream](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus#installing_drivers))

## Installing NVIDIA GPU device drivers

After adding GPU nodes to your cluster, you need to install NVIDIA's device drivers to the nodes. Google provides a DaemonSet that automatically installs the drivers for you.

```sh
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml
```

## Deploy GPU user pods

```sh
kubectl apply -f cuda.yaml
kubectl apply -f tf.yaml
```

## References

- [Scheduling GPUS](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)
- [nvidia-cuda test dockerfile](https://github.com/kubernetes/kubernetes/blob/v1.7.11/test/images/nvidia-cuda/Dockerfile)
