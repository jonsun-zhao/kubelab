#!/bin/bash

esxi_gw_ip=$1

prefix="${esxi_gw_ip%.*}"
suffix="${esxi_gw_ip##*.}"

admin_ws_ip="${prefix}.$((suffix + 2))"

# Safely produce a JSON object containing the result value.
jq -n --arg ip "$admin_ws_ip" '{"ip":$ip}'
