#!/bin/bash

set -e

token=$1
shift
device=$1
shift

# fetch gateway ip from packet api
gw_ip=$(curl -s -X GET --header 'Accept: application/json' --header "X-Auth-Token: ${token}" https://api.packet.net/devices/${device} | jq -r '.ip_addresses[0].gateway')

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg ip "$gw_ip" '{"ip":$ip}'
