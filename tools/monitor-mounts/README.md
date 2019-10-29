# App: monitor-mounts

ref: b/134620802

A DaemonSet that:

1. scrape `systemd`'s mountinfo (`/proc/1/mountinfo`) to get mount counts by `fstype` and `pod_uuid`, and turn them into prometheus format.
    > for mounts do not related to pod, the pod_uuid is default to '00000000-0000-0000-0000-000000000000'

    - A typical `mountinfo` looks like this:

    ```sh
    19 0 254:0 / / ro,relatime shared:1 - ext2 /dev/root ro
    33 27 0:28 / /sys/fs/cgroup/blkio rw,nosuid,nodev,noexec,relatime shared:15 - cgroup cgroup rw,blkio
    298 90 8:1 /var/lib/docker/overlay2 /var/lib/docker/overlay2 rw,nosuid,nodev,relatime - ext4 /dev/sda1 rw,commit=30,data=ordered
    262 323 0:47 / /home/kubernetes/containerized_mounter/rootfs/var/lib/kubelet/pods/d268cb78-afb0-11e9-8f3e-42010a80007f/volumes/kubernetes.io~secret/gke-metadata-server-token-t6gzj rw,relatime shared:142 - tmpfs tmpfs rw
    263 82 0:47 / /var/lib/kubelet/pods/d268cb78-afb0-11e9-8f3e-42010a80007f/volumes/kubernetes.io~secret/gke-metadata-server-token-t6gzj rw,relatime shared:142 - tmpfs tmpfs rw
    ```

2. serve the metrics via localhost:8000
3. metrics are then pushed to stackdiver as custom metics via the `prom-to-sd` sidecar.

## Deploy

```sh
kubectl apply -f k8s/app.yaml
```
