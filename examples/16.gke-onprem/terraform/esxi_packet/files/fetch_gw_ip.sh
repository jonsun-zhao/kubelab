#!/bin/sh

token=$1; shift
device=$1; shift

gw_ip=`curl -s -X GET --header 'Accept: application/json' --header "X-Auth-Token: ${token}" https://api.packet.net/devices/${device} | jq -r '.ip_addresses[0].gateway'`

echo '{"ip": "'$gw_ip'"}'