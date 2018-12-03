#!/bin/bash

in_subnet()
{
  # Determine whether IP address is in the specified subnet.
  #
  # Args:
  #   sub: Subnet, in CIDR notation.
  #   ip: IP address to check.
  #
  # Returns:
  #   1|0
  #
  local ip ip_a mask netmask sub sub_ip rval start end

  # Define bitmask.
  local readonly BITMASK=0xFFFFFFFF

  # Set DEBUG status if not already defined in the script.
  [[ "${DEBUG}" == "" ]] && DEBUG=0

  # Read arguments.
  IFS=/ read sub mask <<< "${1}"
  IFS=. read -a sub_ip <<< "${sub}"
  IFS=. read -a ip_a <<< "${2}"

  # Calculate netmask.
  netmask=$(($BITMASK<<$((32-$mask)) & $BITMASK))

  # Determine address range.
  start=0
  for o in "${sub_ip[@]}"
  do
      start=$(($start<<8 | $o))
  done

  start=$(($start & $netmask))
  end=$(($start | ~$netmask & $BITMASK))

  # Convert IP address to 32-bit number.
  ip=0
  for o in "${ip_a[@]}"
  do
      ip=$(($ip<<8 | $o))
  done

  # Determine if IP in range.
  (( $ip >= $start )) && (( $ip <= $end )) && rval=1 || rval=0

  (( $DEBUG )) &&
      printf "ip=0x%08X; start=0x%08X; end=0x%08X; in_subnet=%u\n" $ip $start $end $rval 1>&2

  echo "${rval}"
}

kget()
{
  local kind=${1:?"Usage: $FUNCNAME [kind]"}
  local dir=${2:-.}
  local cmd=${3:-"kubectl"}
  echo ">> dumping ${kind} to ${dir}/${kind}"
  $cmd get $kind --all-namespaces -o json > $dir/$kind.json
}

list_nodes()
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
    IFS='|' read -r -a arr <<< "$n"
    node_name=${arr[0]}
    pod_cidr=${arr[1]}
    node_ip=${arr[2]}

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
      IFS='|' read -r -a arr <<< "$p"
      # echo ${arr[@]}
      pod_name=${arr[0]}
      pod_ip="n/a"
      # echo ${#arr[@]}

      if (( ${#arr[@]} > 1 )); then
        pod_ip=${arr[1]}
        if (( ! `in_subnet $pod_cidr $pod_ip` )) && [ "$pod_ip" != "$node_ip" ]; then
          pod_ip="!! ${pod_ip}"
        fi
      fi
      
      echo "$pod_ip ($pod_name)"
    done

    echo
  done
}

list_nodes