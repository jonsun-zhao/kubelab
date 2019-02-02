#!/bin/bash

set -e

token=$1
shift
volume=$1
shift

# fetch volume connection information from packet api
set -- $(curl -s -X GET --header 'Accept: application/json' --header "X-Auth-Token: ${token}" https://api.packet.net/storage/${volume} | jq -r '.access| (.ips[]|.), (.iqn)')

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n \
  --arg ip1 "$1" \
  --arg ip2 "$2" \
  --arg target "$3" '{"ip1":$ip1, "ip2":$ip2, "target":$target}'
