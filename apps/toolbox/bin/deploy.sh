#!/bin/bash

git clone -b neil https://github.com/neoseele/gluster-kubernetes.git /root/gluster-kubernetes
cd /root/gluster-kubernetes/deploy/
build-topology.rb > topology.json
./gk-deploy -g --admin-key $HEKETI_ADMIN_SECRET --no-object -y
