#!/bin/bash

kget()
{
  local kind=${1:?"Usage: $FUNCNAME [kind] (i.e. pods)"}
  local dir=${2:-.}
  local cmd=${3:-"kubectl"}
  echo ">> dumping ${kind} to ${dir}/${kind}.json"
  $cmd get $kind --all-namespaces -o json > $dir/$kind.json
}

cutf()
{
  local line=${1:?"Usage: $FUNCNAME [line] [field_number:1]"}
  local f=${2:-1}
  echo `echo "$line" | cut -d"|" -f${f}`
}

knodes()
{
  local refresh=0
  while getopts 'r' opt; do
      case $opt in
          r) refresh=1 ;;
          *) echo 'Error in command line parsing' >&2
             exit 1
      esac
  done
  shift "$(( OPTIND - 1 ))"

  nf="nodes.json"
  pf="pods.json"

  # remove the cache files if refresh flag is on
  if (( $refresh == 1 )); then
    [ -f $nf ] && rm -f $nf
    [ -f $pf ] && rm -f $pf
  fi

  [ -f $nf ] || kget "nodes"
  [ -f $pf ] || kget "pods"
  echo

  nodes=( `cat ${nf} | jq '
      .items[]
      | [
          .metadata.name, .spec.podCIDR,
          (select(.status.addresses)
            | .status.addresses
            | map(select(.type != "Hostname").address)
            | sort
            | join("|")
          )
        ]
      | join("|")
    ' | sed 's/"//g' | sort` )

  for n in ${nodes[@]};
  do
    node_name=`cutf $n 1`
    pod_cidr=`cutf $n 2`
    node_ip=`cutf $n 3`

    echo "[NODE: $node_ip] (podCIDR: $pod_cidr) ($node_name)"
    echo "--------------------------"

    pods=( `cat ${pf} | jq --arg NODENAME "$node_name" '
        .items[]
          | select(.spec.nodeName == $NODENAME)
          | [ .metadata.name, (select(.status.podIP) | .status.podIP) ]
          | join("|")
      ' | sed 's/"//g' | sort`)

    for p in ${pods[@]};
    do
      pod_name=`cutf $p 1`
      pod_ip=`cutf $p 2`

      # check if pod ip is empty
      if [ -n "$pod_id" ]; then
        # check if pod ip is in the pod cidr
        if (! grepcidr "${pod_cidr}" <(echo "${pod_ip}") >/dev/null); then
          # mark the pod unless the pod is using host network
          if [ "$pod_ip" != "$node_ip" ]; then
            pod_ip="[x] ${pod_ip}"
          fi
        fi
      fi
      
      echo "$pod_ip ($pod_name)"
    done

    echo
  done
}

knodes -r
