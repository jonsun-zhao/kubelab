# =====================
#  Aliases
# =====================

alias k="kubectl"
alias ks="k -n kube-system"
alias ki="k -n istio-system"
alias kx="k exec"
alias kw="k -o wide"
alias ksw="ks -o wide"

alias kpod_res='k -o custom-columns="NAME:.metadata.name,\
CPU_REQUEST:.spec.containers[].resources.requests.cpu,\
MEMORY_REQUEST:.spec.containers[].resources.requests.memory,\
MEMORY_LIMIT:.spec.containers[].resources.limits.memory" get pods'

alias g="gcloud"
alias gssh="g compute ssh"
alias gno="g --no-user-output-enabled"
alias gcontainer="g container"
alias gdefault="gactivate default"
alias gcustomer="gactivate customer"

if [[ "$(uname)" == "Linux" ]]; then
  alias base64_decode="base64 -d"
else
  alias base64_decode="base64 -D"
fi

# =====================
#  Utilities
# =====================
browse()
{
  if [ -z "$SSH_TTY" ]; then
    case $OSTYPE in
      darwin*)
        open $*
        ;;
      *)
        python -m webbrowser $* &>/dev/null
        ;;
    esac
  else
    echo "python -m webbrowser $* &>/dev/null"
  fi
}

cutf()
{
  local line=$1
  local f=${2:-1}
  local d=${3:-|}
  echo $(echo "$line" | cut -f${f} -d"${d}")
}

tcurl()
{
  curl -H "Authorization: Bearer $TOKEN" $@
}

# =====================
#  Functions
# =====================

# switch between cloud configs
gactivate()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME GCLOUD_CONFIG"
    return 1
  fi
  local config=$1; shift

  # clean up KUBECONFIG when switching away from the customer config
  if [[ "$config" != "customer" && -n "$KUBECONFIG" ]] ; then
    unset KUBECONFIG
  fi
  if (! gno config configurations activate $config); then
    gno config configurations create $config
    gno config configurations activate $config
  fi
  gno config set account "${USER}@google.com"
}

# switch to customer gcloud config and setup auth token
gauth()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 2 ] ; then
    echo "Usage: $FUNCNAME PROJECT_ID TOKEN"
    return 1
  fi
  local project_id=$1; shift
  local token=$1; shift
  local token_file=~/.cloud_console_token
  echo $token > $token_file

  # switch to customer config
  gcustomer
  gno config set auth/authorization_token_file $token_file
  gno config set core/project $project_id
}

# setup gcloud and kubectl for cluster inspection
kinspect()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ]; then
    echo "Usage: $FUNCNAME CLUSTER_URL [PROJECT_NUMBER]"
    return 1
  fi
  local url=$1; shift

  if [ $ZSH_VERSION ]; then
    # parse cluster inspection url
    # zsh's index is 1 based
    local url_path=${url[(ws:?:)1]}
    local query=${url[(ws:?:)2]}

    # sample url:
    # https://.../clusters/details/us-east1/cache-tier1-us-east1-1
    local location=${url_path[(ws:/:)-2]} # cluster location
    local cluster=${url_path[(ws:/:)-1]} # cluster name

    local regional=false

    # eval the k/v pairs from query into shell variables
    # sample query:
    # project=shopify-xxx&token=AHlSUJtXPumpPB-xxx&tab=details&...
    for p in ${(ws:&:)query};
    do
      k=${p[(ws:=:)1]}
      # echo "k=$k"
      v=${p[(ws:=:)2]}
      # echo "v=$v"
      eval local $k=$v
    done
  else
    # split url by '?'
    local url_arr=( $(IFS=?; echo $url) )
    local url_path=${url_arr[0]}
    local query=${url_arr[1]}

    # split url path by '/'
    local path_arr=( $(IFS=/; echo $url_path) )
    local location=${path_arr[${#path_arr[@]}-2]}
    local cluster=${path_arr[${#path_arr[@]}-1]}

    # split query string by '&'
    local query_arr=( $(IFS=\&; echo $query) )
    for p in ${query_arr[@]};
    do
      k=$(cutf $p 1 '=')
      v=$(cutf $p 2 '=')
      eval local $k=$v
    done
  fi

  echo
  echo "[LOCATION]: $location"
  echo "[PROJECT]: $project"
  echo "[CLUSTER]: $cluster"
  echo "[TOKEN]: $token"
  echo

  if [ -z "$project" ] || [ -z "$token" ]; then
    echo "Error: PROJECT or TOKEN is missing from the url"
    return 1
  fi

  echo ">> Switching gcloud to customer config"
  gauth $project $token

  if [[ $location =~ [[:digit:]]$ ]]; then
    regional=true
  fi

  if $regional; then
    gno config set compute/zone "${location}-a"
  else
    gno config set compute/zone ${location}
  fi

  export KUBECONFIG=~/gke_${project}_${location}_${cluster}-config.txt
  # export CLUSTER=$cluster
  echo ">> Setting KUBECONFIG to $KUBECONFIG"
  echo ">> Getting cluster credentials"
  if $regional; then
    gno container clusters get-credentials $cluster --region $location
  else
    gno container clusters get-credentials $cluster
  fi

  ctx=$(kubectl config current-context)
  echo ">> Setting read-only token"
  # kubectl config unset users.$ctx.auth-provider
  kubectl config set users.$ctx.token "iam-$(gcloud auth print-access-token)^$token"

  # open cluser master vicery if project number is specified
  if [ $# -eq 1 ]; then
    local project_number=$1; shift
    cluster_master_viceroy $project_number $cluster $location
  fi
}

cluster_viceroy()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME PROJECT_NUMBER"
    return 1
  fi

  local project_number=$1; shift
  browse "https://viceroy.corp.google.com/cloud_kubernetes/Project?proj_nums=${project_number}&env=prod"
}

cluster_master_viceroy()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 3 ] ; then
    echo "Usage: $FUNCNAME PROJECT_NUMBER CLUSTER_NAME LOCATION"
    return 1
  fi

  local project_number=$1; shift
  local cluster_name=$1; shift
  local location=$1; shift

  browse "https://viceroy.corp.google.com/cloud_kubernetes/cluster/masters?cluster=${location}%2C+${project_number}%2C+${cluster_name}&env=prod"
}

# get pod by name
kpod()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME POD_NAME [NAMESPACE]"
    return 1
  fi

  pod=$1
  ns=${2:-default}
  echo ">> Pod: $pod"
  echo ">> Namespace: $ns"
  kubectl -n $ns get pod $pod -o json | jq -r '
    "Pod ID = " + .metadata.uid, ("Node = " + .spec.nodeName),
    (.status.containerStatuses[]
      | "Container = \(.name) [\(.containerID)]"
    )
  ' | sed 's#//#:#g'
}

# get pod detail by id
kpod_by_id()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME POD_ID"
    return 1
  fi

  kubectl get pods --all-namespaces -o json | jq -r ".items[] | select(.metadata.uid == \"$1\")"
}

kpod_all()
{
  kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{"\n"}[ns]{.metadata.namespace} [pod]{.metadata.name} [pod_id]{.metadata.uid} [node]{.spec.nodeName} [status]{.status.phase}{"\n"}{range .status.containerStatuses[*]}>> [c]{.name} {.containerID}{"\n"}{end}{"\n"}{end}' | sed 's#//#|#g'
}

kpod_all_x()
{
  kubectl get pods --all-namespaces -o json | jq -r '
    .items[]
    | (.metadata.namespace + " " + .metadata.name + " " + .metadata.uid + " " + .spec.nodeName + " " + .status.phase),
      (
        .status.containerStatuses[] | (">> " + .name + " " + .containerID)
      ),
      ""
  ' | sed "s#//#:#g"
}

# get pid from container id
kpid_by_container_id()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 2 ] ; then
    echo "Usage: $FUNCNAME NODE CONTAINER_ID"
    return 1
  fi

  # get pid from docker inspect
  pid=$(gssh $1 -- "sudo docker inspect --format="{{.Spec.Pid}}" $2 2>/dev/null")

  # try crictl if nothing is found in docker
  if [ $? -eq 0 ]; then
    echo $pid
  else
    data=$(gssh $1 -- "sudo crictl inspect $2 2>/dev/null")
    [ ! -z "$data" ] && echo $data | jq '.info.pid'
  fi
}

# dump object by kind
kdump()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME KIND (i.e. pods)"
    return 1
  fi

  local kind=$1
  local dir=${2:-.}
  local cmd=${3:-"kubectl"}

  echo ">> dumping ${kind} to ${dir}/${kind}.json"
  $cmd get $kind --all-namespaces -o json > $dir/$kind.json
}

kdump_all()
{
  local cmd="k-dev"
  local dir="$($cmd config current-context)_$(date +%s)"

  [ -d $dir ] || mkdir $dir

  local r1=( `$cmd api-resources --verbs=list --namespaced=false -o name | cut -d "." -f1 | sort -u` )
  local r2=( `$cmd api-resources --verbs=list -o name | cut -d "." -f1 | sort -u` )
  local resources=( "${r1[@]}" "${r2[@]}" )
  local unique_resources=( $(echo "${resources[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ') )

  # echo "dumping all resources"
  for k in $unique_resources[@];
  do
    # skip secrets
    [[ $k == "secrets" ]] && continue
    kdump $k $dir $cmd
  done

  echo -e "\n** output directory:  ${dir} **"
}

# list nodes with pods
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

  [ -f $nf ] || kdump "nodes"
  [ -f $pf ] || kdump "pods"
  echo

  nodes=( $(cat ${nf} | jq -r '
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
    ' | sort) )

  for n in ${nodes[@]};
  do
    local node_name=$(cutf $n 1)
    local pod_cidr=$(cutf $n 2)
    local node_ip=$(cutf $n 3)

    echo "[NODE: $node_ip] (podCIDR: $pod_cidr) ($node_name)"
    echo "--------------------------"

    local pods=( $(cat ${pf} | jq -r --arg NODENAME "$node_name" '
        .items[]
          | select(.spec.nodeName == $NODENAME)
          | [ .metadata.name, (select(.status.podIP) | .status.podIP) ]
          | join("|")
      ' | sort) )

    for p in ${pods[@]};
    do
      local pod_name=$(cutf $p 1)
      local pod_ip=$(cutf $p 2)

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

# check if any node is not logging to SD
knodes_logging()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME NODE_PREFIX"
    return 1
  fi

  local node_prefix=$1
  local minutes='60'
  local project=$(gcloud config get-value core/project)
  local date=''

  if [ "$(uname)" = "Darwin" ]; then
    # Do something under Mac OS X platform
    date=$(date -v-${minutes}M -u +"%Y-%m-%dT%H:%M:%SZ")
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    date=$(date -d "${minutes} minutes ago" -u +"%Y-%m-%dT%H:%M:%SZ")
  fi

  local tmpfile=$(mktemp)
  exec 3>"$tmpfile"
  exec 4<"$tmpfile"
  rm $tmpfile

  # echo $node_prefix
  # echo $project
  # echo $date

  # read log into the temp file
  echo ">> fetching kubelet log from ${node_prefix} nodes in the last $minutes minutes"

  gcloud logging read --format json --freshness 1h "
    resource.type=\"gce_instance\"
    logName=\"projects/${project}/logs/kubelet\"
    jsonPayload._HOSTNAME:\"${node_prefix}\"
    timestamp>\"${date}\"
  " >&3

  # local data=`cat <&4`
  local data=$(cat <&4 | jq '.[] | [.jsonPayload._HOSTNAME]' | sort | uniq)
  local nodes=( $(kubectl get nodes -o jsonpath='{.items[*].spec.providerID}') )
  local all_good=true
  # echo $data
  for n in ${nodes[@]};
  do
    node_name=$(echo $n | awk -F/ '{print $NF}')
    if [[ ! "$data" =~ "$node_name" ]]; then
      echo "[x] node $node_name is not logging"
      $all_good && all_good=false
    fi
  done
  $all_good && echo ">> all nodes are logging"
}

# list docker image ids in the GCR of the current project
gdocker_image_id()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME IMAGE_NAME"
    return 1
  fi

  local image=$1
  local project=$(gcloud config get-value core/project)
  local token=$(gcloud auth print-access-token)

  local url="https://gcr.io/v2/$project/$image"
  local j="Content-Type: application/json"
  local t="Authorization: Bearer $token"

  # echo $image
  # echo $project
  # echo $url
  # echo $token

  # → cat tag_list | jq '.manifest | to_entries[] | [.key, .value]'
  # [
  #   "sha256:09248ec73e524dc320e378c4a378ca1804692644ebaa24b95cf9c1d5d0f01196",
  #   {
  #     "imageSizeBytes": "5215719",
  #     "layerId": "",
  #     "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
  #     "tag": [],
  #     "timeCreatedMs": "1532434848921",
  #     "timeUploadedMs": "1532434855964"
  #   }
  # ]

  for x in $(curl -s -H "$j" -H "$t" $url/tags/list 2>/dev/null | jq -r '
      .manifest
        | to_entries[]
        | [.key, .value.imageSizeBytes]
        | join("|")
    ');
  do
    local tag=$(cutf $x 1)
    local size=$(cutf $x 2) # imageSizeBytes
    local image_id=$(curl -s -H "$j" -H "$t" $url/manifests/$tag 2>/dev/null | jq -r '.config.digest')
    echo "$image|$image_id|$size"
  done
}

# get token by serviceaccount
ktoken_by_sc()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME SERVICE_ACCOUNT [NAMESPACE:-default]"
    return 1
  fi

  sc=$1
  namespace=${2:-default}
  kubectl -n $namespace get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='$sc')].data.token}"|base64_decode
}

# get token by secret
ktoken_by_secret()
{
  [ $ZSH_VERSION ] && FUNCNAME=${funcstack[1]}

  if [ $# -lt 1 ] ; then
    echo "Usage: $FUNCNAME SECRET [NAMESPACE:-default]"
    return 1
  fi

  secret=$1
  namespace=${2:-default}

  kubectl -n $namespace get secret $secret -o jsonpath="{.data.token}"|base64_decode
}