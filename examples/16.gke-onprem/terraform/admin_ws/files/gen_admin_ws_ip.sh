#!/bin/bash

esxi_host_ip=$1
shift

prefix="${esxi_host_ip%.*}"
suffix="${esxi_host_ip##*.}"

admin_ws_ip="${prefix}.$((suffix + 1))"

# Safely produce a JSON object containing the result value.
jq -n --arg ip "$admin_ws_ip" '{"ip":$ip}'
