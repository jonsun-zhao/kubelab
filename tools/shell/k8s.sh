# =====================
#  Aliases
# =====================

alias k="kubectl"
alias ks="k -n kube-system"
alias ki="k -n istio-system"
alias kg="k -n gke-system"
alias kns="k -n knative-serving"
alias kx="k exec"
alias kw="k -o wide"
alias ksw="ks -o wide"
alias kj="k -o json"
alias ksj="ks -o json"
alias kiwl="k -n istio-workload"

alias kpod_res='k -o custom-columns="NAME:.metadata.name,\
CPU_REQUEST:.spec.containers[].resources.requests.cpu,\
MEMORY_REQUEST:.spec.containers[].resources.requests.memory,\
MEMORY_LIMIT:.spec.containers[].resources.limits.memory" get pods'

alias g="gcloud"
alias gssh='g compute ssh --ssh-flag="-o LogLevel=QUIET"'
alias gno="g --no-user-output-enabled"
alias gcontainer="g container"
alias gdefault="gactivate default"
alias gcustomer="gactivate customer"

alias kcurl="kdebug -i gcr.io/nmiu-play/curl-http2"
alias kfortio="kdebug -i gcr.io/nmiu-play/fortio"
alias khammer="kdebug -i gcr.io/nmiu-play/hammer -c bash"

if [[ "$(uname)" == "Linux" ]]; then
  alias base64_decode="base64 -d"
else
  alias base64_decode="base64 -D"
fi

# =====================
#  Variables
# =====================

export NODES_JSON="nodes.json"
export PODS_JSON="pods.json"
export SERVICES_JSON="services.json"
export ENDPOINTS_JSON="endpoints.json"

# =====================
#  Utils
# =====================

browse() {
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

# cutf() {
#   local line=$1
#   local f=${2:-1}
#   local d=${3:-|}
#   echo $(echo "$line" | cut -f${f} -d"${d}")
# }

trim() {
  local var="$*"

  # convert newline to space
  var=$(echo $var | tr '\n' ' ')
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}"
  echo -n "$var"
}

# dump object by type
kdump() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME KIND (i.e. pods)"
    return 1
  fi

  local kind=$1
  local dir=${2:-.}
  local cmd=${3:-"kubectl"}

  echo ">> dumping ${kind} to ${dir}/${kind}.json"
  $cmd get $kind --all-namespaces -o json >$dir/$kind.json
}

# dump anything and everything
kdump_all() {
  local cmd="k-dev"
  local dir="$($cmd config current-context)_$(date +%s)"

  [ -d $dir ] || mkdir $dir

  $cmd cluster-info dump --all-resources --output-directory=$dir
  echo -e "\n** output directory:  ${dir} **"
}

ka() {
  kubectl "$@" --all-namespaces
}

# =====================
#  GCP Helpers
# =====================

# doesn't work while inspecting customer's project...
gproject() {
  local project_id=${1:-$(gcloud config get-value core/project)}
  local token=${2:-$(gcloud auth print-access-token)}
  curl -s -H "Authorization: Bearer $token" "https://cloudresourcemanager.googleapis.com/v1beta1/projects/${project_id}"
}

gproject_number() {
  gproject | jq -r ".projectNumber"
}

# switch between cloud configs
gactivate() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME GCLOUD_CONFIG"
    return 1
  fi
  local config=$1
  shift

  # clean up KUBECONFIG when switching away from the customer config
  if [[ "$config" != "customer" && -n "$KUBECONFIG" ]]; then
    unset KUBECONFIG
  fi
  if (! gno config configurations activate $config); then
    gno config configurations create $config
    gno config configurations activate $config
  fi
  gno config set account "${USER}@google.com"
}

# switch to customer gcloud config and setup auth token
gauth() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 2 ]; then
    echo "Usage: $FUNCNAME PROJECT_ID TOKEN"
    return 1
  fi
  local project_id=$1
  local token=$2
  local token_file=~/.cloud_console_token
  echo $token >$token_file

  # switch to customer config
  gcustomer
  gno config set auth/authorization_token_file $token_file
  gno config set core/project $project_id
}

# setup gcloud and kubectl for cluster inspection
kinspect() {
  if [ -n "$ZSH_VERSION" ]; then
    FUNCNAME=${funcstack[1]}
    setopt sh_word_split
    setopt KSH_ARRAYS # emulate the zero based ksh array
  fi

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME CLUSTER_URL [PROJECT_NUMBER]"
    return 1
  fi
  local url=$1
  shift

  # split url by '?'
  set -- $(
    IFS=?
    echo $url
  )
  local url_path=$1
  local query=$2

  # split url path by '/'
  local path_arr=($(
    IFS=/
    echo $url_path
  ))
  local location=${path_arr[${#path_arr[@]} - 2]}
  local cluster=${path_arr[${#path_arr[@]} - 1]}

  # split query string by '&'
  local query_arr=($(
    IFS=\&
    echo $query
  ))
  for p in ${query_arr[@]}; do
    set -- $(
      IFS=\=
      echo $p
    )
    local k=$1
    local v=$2
    eval local $k=$v
  done

  echo
  echo "[LOCATION]: $location"
  echo "[CLUSTER]: $cluster"
  echo "[PROJECT]: $project"
  echo "[TOKEN]: $token"
  echo

  if [ -z "$project" ] || [ -z "$token" ]; then
    echo "Error: PROJECT or TOKEN is missing from the url"
    return 1
  fi

  echo ">> Switching gcloud to customer config"
  gauth $project $token

  local regional=false

  if [[ $location =~ [[:digit:]]$ ]]; then
    regional=true
  fi

  if $regional; then
    gno config set compute/zone "${location}-a"
  else
    gno config set compute/zone ${location}
  fi

  export KUBECONFIG=~/gke_${project}_${location}_${cluster}-config.txt
  echo ">> Setting KUBECONFIG to $KUBECONFIG"
  echo ">> Getting cluster credentials"
  if $regional; then
    gno container clusters get-credentials $cluster --region $location
  else
    gno container clusters get-credentials $cluster
  fi

  local ctx=$(kubectl config current-context)
  echo ">> Setting read-only token"
  # kubectl config unset users.$ctx.auth-provider
  kubectl config set users.$ctx.token "iam-$(gcloud auth print-access-token)^$token"

  # open the cluser master vicery page if project number is provided
  if [ "$#" -eq 1 ]; then
    local project_number=$1
    kcluster_master_viceroy $project_number $cluster $location
  fi

  # reset array behavior back to zsh default
  [ -n "$ZSH_VERSION" ] && unsetopt KSH_ARRAYS
}

# list docker image ids in current project's gcr.io repository
# Useful for cleaning up unwanted docker images in GCS
gdocker_image_id() {
  if [ -n "$ZSH_VERSION" ]; then
    FUNCNAME=${funcstack[1]}
    setopt sh_word_split
  fi

  if [ "$#" -lt 1 ]; then
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
    '); do
    set -- $(
      IFS=\|
      echo $x
    )
    local tag=$1  # tag id
    local size=$2 # imageSizeBytes

    local image_id=$(curl -s -H "$j" -H "$t" $url/manifests/$tag 2>/dev/null | jq -r '.config.digest')
    echo "$image|$image_id|$size"
  done
}

# open cluster viceroy page by project number
kcluster_viceroy() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME PROJECT_NUMBER"
    return 1
  fi

  local project_number=$1
  browse "https://viceroy.corp.google.com/cloud_kubernetes/Project?proj_nums=${project_number}&env=prod"
}

# open cluster master viceroy page by project number
kcluster_master_viceroy() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 3 ]; then
    echo "Usage: $FUNCNAME PROJECT_NUMBER CLUSTER_NAME LOCATION"
    return 1
  fi

  local project_number=$1
  local cluster_name=$2
  local location=$3

  browse "https://viceroy.corp.google.com/cloud_kubernetes/cluster/masters?cluster=${location}%2C+${project_number}%2C+${cluster_name}&env=prod"
}

# fetch stackdriver logs
glogs() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  local usage="Usage: $FUNCNAME -f FILTER -s [START_TIME] -e [END_TIME] -o [OUTPUT]"
  local start_time=$(tzutil.rb -q -u -o '\-3600') # an hour ago
  local end_time=$(tzutil.rb -q -u)               # now
  local filter=''
  local output='/tmp/output.json'

  local OPTIND
  while getopts ':s:e:f:o:' opt; do
    case $opt in
    s) start_time=${OPTARG} ;;
    e) end_time=${OPTARG} ;;
    f) filter=${OPTARG} ;;
    o) output=${OPTARG} ;;
    *)
      echo $usage >&2
      return 1
      ;;
    esac
  done
  shift "$((OPTIND - 1))"

  if [ -z "$filter" ]; then
    echo "FILTER is required\n"
    echo $usage
    return 1
  fi

  local query="$(trim $filter) timestamp>\"${start_time}\" timestamp<=\"${end_time}\""

  echo "== query ==\n$query\n"
  echo "== output ==\n$output"

  gcloud logging read --format=json --order asc "${query}" >$output
}

# =====================
#  k8s Helpers
# =====================

# get pod by id
kpod_by_id() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME POD_ID"
    return 1
  fi

  kubectl get pods --all-namespaces -o json | jq -r ".items[] | select(.metadata.uid == \"$1\")"
}

# get pid by container id
kpid_by_container_id() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 2 ]; then
    echo "Usage: $FUNCNAME NODE CONTAINER_ID"
    return 1
  fi

  # get pid from docker inspect
  local pid=$(gssh $1 -- "sudo docker inspect --format="{{.State.Pid}}" $2 2>/dev/null")

  # try crictl if nothing is found in docker
  if [ $? -eq 0 ]; then
    echo $pid
  else
    echo $(gssh $1 -- "sudo crictl inspect $2 2>/dev/null") | jq -r '.info.pid'
  fi
}

# get token by serviceaccount
ktoken_by_serviceaccount() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME SERVICE_ACCOUNT [NAMESPACE:-default]"
    return 1
  fi

  local sc=$1
  local namespace=${2:-default}
  kubectl -n $namespace get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='$sc')].data.token}" | base64_decode
}

# get token by secret
ktoken_by_secret() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME SECRET [NAMESPACE:-default]"
    return 1
  fi

  local secret=$1
  local namespace=${2:-default}

  kubectl -n $namespace get secret $secret -o jsonpath="{.data.token}" | base64_decode
}

# get cluster autoscaler status
kautoscaler_status() {
  kubectl -n kube-system get configmap cluster-autoscaler-status -o json | jq -r '.data.status'
}

# check if any node is not logging to stackdriver in X minutes (default: 60 minutes)
knodes_logging() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME NODE_PREFIX [MINUTES:-60]"
    return 1
  fi

  local node_prefix=$1
  local minutes=${2:-60}
  local project=$(gcloud config get-value core/project)
  local date=''

  if [[ "$(uname)" == "Darwin" ]]; then
    date=$(date -v-${minutes}M -u +"%Y-%m-%dT%H:%M:%SZ")
  elif [[ "$(uname)" == "Linux" ]]; then
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

  gcloud logging read --format=json --order=desc "
    resource.type=\"gce_instance\"
    logName=\"projects/${project}/logs/kubelet\"
    jsonPayload._HOSTNAME:\"${node_prefix}\"
    timestamp>\"${date}\"
  " >&3

  # local data=`cat <&4`
  local data=$(cat <&4 | jq -r '.[] | .jsonPayload._HOSTNAME' | sort -u)
  local nodes=($(kubectl get nodes -o jsonpath='{.items[*].spec.providerID}'))
  local all_good=true
  # echo $data
  for n in ${nodes[@]}; do
    local node_name=$(echo $n | awk -F/ '{print $NF}')
    # echo $node_name
    if [[ ! "$data" =~ "$node_name" ]]; then
      echo "[x] node $node_name is not logging"
      $all_good && all_good=false
    fi
  done
  $all_good && echo ">> all nodes are logging"
}

# create a debug kube-dns pod with dns query logging enabled
kcreate_kubedns_debug_pod() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME POD_NAME"
    return 1
  fi

  local pod=$1

  kubectl apply -f <(kubectl get pod -n kube-system ${pod} -o json | jq -e '
    (
      (.spec.containers[] | select(.name == "dnsmasq") | .args) += ["--log-queries"]
    )
    | (.metadata.name = "kube-dns-debug")
    | (del(.metadata.labels."pod-template-hash"))
  ')
}

kdebug() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  local usage="Usage: $FUNCNAME -i image [-n namespace] [-a serviceaccount] [-c command]"

  local OPTIND
  while getopts ":n:i:c:a:" arg; do
    case $arg in
    n) local ns=${OPTARG} ;;
    i) local image=${OPTARG} ;;
    c) local command=${OPTARG} ;;
    a) local sa=${OPTARG} ;;
    *)
      echo $usage
      return 1
      ;;
    esac
  done
  shift $((OPTIND-1))

  if [ -z "${image}" ]; then
    echo "$usage"
    return 1
  fi

  local ns=${ns:-default}
  local sa=${sa:-default}
  local command=${command:-sh}

  cmd="kubectl run debug-`date +%s` -it --generator=run-pod/v1 --rm -n $ns --image=${image} --serviceaccount=${sa} -- $command"
  echo "(${cmd})"
  eval $cmd
}

# jq node details
jq_node() {
  jq -r '
    [
      .metadata.name, .spec.podCIDR,
      (select(.status.addresses)
        | .status.addresses
        | map(select(.type != "Hostname").address)
        | sort
        | join("/")
      )
    ] | join(" ")
  '
}

# jq pod details
jq_pod() {
  local detail='
    (
      [
        "name=[\(.metadata.name)]",
        "namespace=[\(.metadata.namespace)]",
        "uid=[\(.metadata.uid)]",
        "nodeName=[\(.spec.nodeName)]",
        "podIP=[\(.status.podIP)]",
        "status=[\(.status.phase)]"
      ] | join(" ")
    ),
    (
      .status.containerStatuses[] | [
        "#container: name=[\(.name)]",
        "image=[\(.image)]",
        "ready=[\(.ready)]",
        .containerID
      ] | join(" ")
    ),
    (
      select(.status.initContainerStatuses != null) |
        .status.initContainerStatuses[] | [
          "#initContainer: name=[\(.name)]",
          "image=[\(.image)]",
          "ready=[\(.ready)]",
          .containerID
        ] | join(" ")
    )
  '
  jq -r "
    (
      select(.items?)
      | .items[]
      | `echo ${detail}`, ( \"\" )
    ),
    (
      select(.items?|not)
      | `echo ${detail}`
    )
  "
}

# jq service details
jq_service() {
  local detail='
    (
      [
        "name=[\(.metadata.name)]",
        "namespace=[\(.metadata.namespace)]",
        "type=[\(.spec.type)]",
        "clusterIP=[\(.spec.clusterIP)]",
        "loadBalancerIP=[\(.spec.loadBalancerIP)]",
        "externalTrafficPolicy=[\(.spec.externalTrafficPolicy)]"
      ] | join(" ")
    ),
    (
      .spec.ports[] | [
        "#port: name=[\(.name)]",
        "protocol=[\(.protocol)]",
        "port=[\(.port)]",
        "nodePort=[\(.nodePort)]",
        "targetPort=[\(.targetPort)]"
      ] | join(" ")
    )
  '

  jq -r "
    (
      select(.items?)
      | .items[]
      | `echo ${detail}` , ( \"\" )
    ),
    (
      select(.items?|not)
      | `echo ${detail}`
    )
  "
}

# jq endpoint details
jq_endpoint() {
  jq -r '
    .subsets[]
    | (.addresses[] | [.ip, .targetRef.name, .nodeName] | join("|"))
  '
}

jq_raw() {
  jq -r '
    (
      select(.items?)
      | .items[]
      | [
          "name=[\(.metadata.name)]",
          "namespace=[\(.metadata.namespace)]",
          "uid=[\(.metadata.uid)]"
        ]
      | @tsv
    ),
    (
      select(.items?|not)
    )
  '
}

jq_raw_name() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}
  
  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME NAME"
    return 1
  fi

  jq -r '
    (
      select(.items?)
      | .items[]
      | select(.metadata.name == "'${1}'")
    ),
    (
      select(.items?|not)
    )
  '
}

jq_flat() {
  jq -j '
    [
      [
        paths(scalars)
        | map(
          if type == "number"
          then "[" + tostring + "]"
          else "." + .
          end
        ) | join("")
      ],
      [
        .. | select(scalars) | @json
      ]
    ]
    | transpose
    | map(join(" = ") + "\n")
    | join("") 
  '
}



# =========================
#  Cluster Dump Helpers
# =========================

# get pod by name
kpod() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME POD_NAME [NAMESPACE:-default]"
    return 1
  fi

  if [ ! -f $PODS_JSON ]; then
    kdump "pods"
    echo
  fi

  local pod=$1
  local namespace=${2:-default}

  cat $PODS_JSON | jq -r '
    .items[] | select(.metadata.name == "'$pod'" and .metadata.namespace == "'$namespace'")
  ' | jq_pod | sed 's#://#=#g'
}

# get pods
kpods() {
  if [ -f $PODS_JSON ]; then
    echo ">> using cached file [$PODS_JSON]\n"
  else
    kdump "pods"
    echo
  fi

  cat $PODS_JSON | jq_pod
}

# get node by name
# lists the pods running on it as well
knode() {
  if [ -n "$ZSH_VERSION" ]; then
    FUNCNAME=${funcstack[1]}
    setopt sh_word_split
  fi

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME NODE_NAME"
    return 1
  fi

  if [ ! -f $NODES_JSON ] || [ ! -f $PODS_JSON ]; then
    kdump "nodes"
    kdump "pods"
    echo
  fi

  local node_name=$1
  set -- $(cat $NODES_JSON | jq -r '
    .items[] | select(.metadata.name == "'$node_name'")
  ' | jq_node)
  local pod_cidr=$2
  local node_ip=$3

  echo "NODE: [$node_name] (podCIDR: $pod_cidr) ($node_ip)"
  echo "--------------------------"

  local pods=($(cat $PODS_JSON | jq -r '
        .items[]
          | select(.spec.nodeName == "'$node_name'")
          | [ .metadata.name, .metadata.namespace, (select(.status.podIP) | .status.podIP) ]
          | join("|")
      ' | sort))

  for p in ${pods[@]}; do
    set -- $(
      IFS=\|
      echo $p
    )
    local pod_name=$1
    local namespace=$2
    local pod_ip=$3

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

    echo "$pod_ip ($namespace:$pod_name)"
  done

  echo
}

# get nodes and their pods
knodes() {
  if [ -n "$ZSH_VERSION" ]; then
    FUNCNAME=${funcstack[1]}
    setopt sh_word_split
  fi

  if [ -f $NODES_JSON ] && [ -f $PODS_JSON ]; then
    echo ">> using cached files [ $NODES_JSON, $PODS_JSON ]\n"
  else
    kdump "nodes"
    kdump "pods"
    echo
  fi

  local nodes=($(cat $NODES_JSON | jq -r '.items[] | .metadata.name' | sort))

  for n in ${nodes[@]}; do
    knode $n
  done
}

# get service by name
kservice() {
  if [ -n "$ZSH_VERSION" ]; then
    FUNCNAME=${funcstack[1]}
    setopt sh_word_split
  fi

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME SERVICE_NAME [NAMESPACE:-default]"
    return 1
  fi

  if [ -f $SERVICES_JSON ] && [ -f $PODS_JSON ] && [ -f $ENDPOINTS_JSON ]; then
    # echo ">> using cached files [$SERVICES_JSON, $PODS_JSON, $ENDPOINTS_JSON]\n"
    true
  else
    kdump "services"
    kdump "endpoints"
    kdump "pods"
    echo
  fi

  local service=$1
  local namespace=${2:-default}

  cat $SERVICES_JSON | jq -r '
    .items[] | select(.metadata.name == "'$service'" and .metadata.namespace == "'$namespace'")
  ' | jq_service

  local endpoints=($(cat $ENDPOINTS_JSON | jq -r '
        .items[] | select(.metadata.name == "'$service'" and .metadata.namespace == "'$namespace'")
      ' | jq_endpoint
      )
  )

  # echo $endpoints

  for e in ${endpoints[@]}; do
    # the pod/node sections can be empty
    #
    # i.e. for service "kubernetes" in namespace "default"
    #
    # $e => "35.203.90.158||"

    set -- $(
      IFS=\|
      echo $e
    )

    local ep_ip=$1
    local pod=$2
    local node=$3

    local ep_str="#endpoint: ip=[${ep_ip}] pod=[${pod}] node=[${node}]"

    if [ -z $pod ]; then
      echo $ep_str
      return
    fi

    local pod_ip=$(cat $PODS_JSON | jq -r '
      .items[]
        | select(.metadata.name == "'$pod'" and .metadata.namespace == "'$namespace'")
        | (.status.podIP|tostring)
    ')

    if [ "$ep_ip" = "$pod_ip" ]; then
      echo $ep_str
    else
      echo "${ep_str} [<< endpoint doesn't match with the pod IP: ${pod_ip}]"
    fi
  done
}

# get services
kservices() {
  if [ -n "$ZSH_VERSION" ]; then
    FUNCNAME=${funcstack[1]}
    setopt sh_word_split
  fi

  if [ -f $SERVICES_JSON ] && [ -f $PODS_JSON ] && [ -f $ENDPOINTS_JSON ]; then
    echo ">> using cached files [$SERVICES_JSON, $PODS_JSON, $ENDPOINTS_JSON]\n"
  else
    kdump "services"
    kdump "endpoints"
    kdump "pods"
    echo
  fi

  local services=($(cat $SERVICES_JSON | jq -r '.items[] | [.metadata.name, .metadata.namespace] | join("|")'))

  for s in ${services[@]}; do
    set -- $(
      IFS=\|
      echo $s
    )
    local name=$1
    local namespace=$2
    # echo "$name ($namespace)"

    kservice $name $namespace
    echo
  done
}

# get container's virtual nic name from the node
kcontainer_nic() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME POD_NAME [NAMESPACE:-default] [CONTAINER_NAME]"
    return 1
  fi

  local pod=$1
  local namespace=${2:-default}
  local container=$3
  local iflink=""

  if [ -n "${container}" ]; then
    iflink=$(k -n ${namespace} exec ${pod} -c ${container} -it -- /bin/sh -c 'cat /sys/class/net/eth0/iflink' | tr -d '[:space:]')
  else
    iflink=$(k -n ${namespace} exec ${pod} -it -- /bin/sh -c 'cat /sys/class/net/eth0/iflink' | tr -d '[:space:]')
  fi

  # echo $iflink
  local node=$(k -n ${namespace} get pod ${pod} -o json | jq -r '.spec.nodeName|tostring' | tr -d '[:space:]')
  local nic=$(gssh $node -- "grep ${iflink} /sys/class/net/*/ifindex | cut -d/ -f5")
  echo "node: $node"
  echo "nic: $nic"
}

knode_usage() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME NODE_NAME"
    return 1
  fi

  local node=$1
  echo "Node: [${node}]"
  echo "--------------------------"
  k describe node $node | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- | sed -e 's/^[[:space:]]*//'
  echo
}

knodes_iptables-save() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -gt 1 ]; then
    echo "Usage: $FUNCNAME [NODE_NAME]"
    return 1
  fi

  local node=$1
  local epoch=$(date +%s)

  if [ -n "$node" ]; then
    echo "> dumping iptables rules from ${node}"
    gssh $node -- sudo iptables-save > ${node}.${epoch}
  else
    for h in `kubectl get nodes -o json | jq -r '.items[]|.metadata.name'`; 
    do 
      echo "> dumping iptables rules from ${h}"
      gssh $h -- sudo iptables-save > ${h}.${epoch}
    done
  fi
}

# =====================
#  istio Helpers
# =====================

istio_dump_proxy_config() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  if [ "$#" -lt 1 ]; then
    echo "Usage: $FUNCNAME POD_NAME [NAMESPACE:-default] [ISTIOCTL_CMD:-istioctl]"
    return 1
  fi

  local pod=$1
  local namespace=${2:-default}
  local cmd=${3:-istioctl}

  local output_dir="${pod}_${namespace}_$(date +%s)"
  [ -d $output_dir ] || mkdir -p $output_dir

  local configs=(cluster listener route endpoint bootstrap)

  for i in "${configs[@]}"; do
    echo "> dumping $i to ${output_dir}/${i}.json"
    $cmd proxy-config $i -n ${namespace} ${pod} -o json >${output_dir}/${i}.json
  done
}

# =====================
#  helm Helpers
# =====================

keel_run() {
  [ -n "$ZSH_VERSION" ] && FUNCNAME=${funcstack[1]}

  local usage="Usage: $FUNCNAME -r release [-n namespace][-a|-d|-v] [-f /path/to/values-xxx.yaml]"

  local OPTIND
  while getopts ":r:n:advf:" arg; do
    case $arg in
      r) local release=${OPTARG} ;;
      n) local namespace=${OPTARG} ;;
      a) local action="apply" ;;
      d) local action="delete" ;;
      v) local action="check" ;;
      f) local mod_file=${OPTARG} ;;
      *)
        echo $usage
        return 1
        ;;
    esac
  done
  shift $((OPTIND-1))

  local namespace=${namespace:-default}

  if [ ! -f "./Chart.yaml" ]; then
    echo "`pwd` is not a helm chart directory"
    return 1
  fi

  if [ -z "${release}" ]; then
    echo $usage
    return 1
  fi

  local cmd="helm template . --name ${release} --namespace ${namespace}"

  if [ -n "${mod_file}" ]; then
    cmd="${cmd} -f ${mod_file}"
  fi

  cmd="${cmd} ${@} | sed 's/RELEASE/${release}/g'"
  # echo "cmd: ${cmd}"

  local yaml="$(eval $cmd)"

  case $action in
  "check") echo "${yaml}" | kubectl apply --dry-run -f - ;;
  "apply") echo "${yaml}" | kubectl apply -f - ;;
  "delete") echo "${yaml}" | kubectl delete -f - ;;
  *) echo "${yaml}" ;;
  esac
}