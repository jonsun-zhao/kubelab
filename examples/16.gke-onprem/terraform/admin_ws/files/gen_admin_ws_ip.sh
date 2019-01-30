#!/bin/bash

esxi_host_ip=$1; shift

prefix="${esxi_host_ip%.*}"
suffix="${esxi_host_ip##*.}"

admin_ws_ip="${prefix}.$((suffix+1))"

echo '{"ip": "'$admin_ws_ip'"}'
