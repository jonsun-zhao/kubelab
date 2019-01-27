#!/bin/sh

out="files/admin_ws_tmp.json"
template="files/admin_ws.json.template"

token=$1; shift
device=$1; shift

gw=`curl -s -X GET --header 'Accept: application/json' --header "X-Auth-Token: ${token}" https://api.packet.net/devices/${device} | jq -r '.ip_addresses[0].gateway'`

cat $template | sed "s/CHANGEME/${gw}/" > $out