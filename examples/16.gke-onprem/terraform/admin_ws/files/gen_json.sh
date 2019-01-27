#!/bin/sh

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
template="${dir}/admin_ws.json.template"
out="${dir}/admin_ws_tmp.json"

gw_ip=$1; shift
cat $template | sed "s/CHANGEME/${gw_ip}/" > $out