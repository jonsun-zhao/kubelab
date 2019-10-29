# Storage

## Playbooks

* [pvc/pv - ReadOnlyMany](pv-rox)
  * demonstrate multiple pods can mount the same PV in ReadOnlyMany mode

* [pvc/pv - ReadWriteOnce](pv-rwo)
  * demonstrate only one pod can mount PV in ReadWriteOnce mode

* [gce-pd](gce-pd)
  * demonstrate how pod can mount GCE-PD directly

* [local-volume](../05.statefulset/nginx/local-volume)
  * demonstrate how local-volume is created and used