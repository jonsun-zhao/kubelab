# Absolute path to a GKE bundle on disk
bundlepath: "/var/lib/gke/bundles/gke-onprem-vsphere-${gke_op_version}.tgz"
# Specify which vCenter resources to use for deployment
vcenter:
  # The credentials and address GKE should use to connect to vCenter
  credentials:
    address: "172.16.10.2"
    username: "${vcenter_username}"
    password: "${vcenter_password}"
  datacenter: "GKE On-Prem"
  datastore: "datastore1"
  cluster: "GKE On-Prem"
  network: "internal vm network"
  resourcepool: "GKE On-Prem"
  # Provide the name for the persistent disk to be used by the deployment (ending
  # in .vmdk). Any directory in the supplied path must be created before deployment.
  # Not required when adding additional user clusters
  datadisk: "gke-on-prem/gke-on-prem-data-disk1.vmdk"
  # Provide the path to vCenter CA certificate pub key for SSL verification
  cacertpath: "/home/ubuntu/vspherecert.pem"
# Specify the proxy configuration.
proxy:
  # The URL of the proxy
  url: ""
  # The domains and IP addresses excluded from proxying
  noproxy: ""
# Specify admin cluster settings for a fresh GKE On-Prem deployment. Omit this section
# and use the --adminconfig flag when adding a new user cluster to an existing deployment
admincluster:
  # In-Cluster vCenter configuration
  vcenter:
    # If specified it overwrites the network field in global vcenter configuration
    network: ""
  # # The absolute or relative path to the yaml file to use for static IP allocation.
  # # Do not include if using DHCP
  ipblockfilepath: "/home/ubuntu/admin-static.yaml"
  # # Specify pre-defined nodeports if using "manual" load balancer mode
  manuallbspec:
    ingresshttpnodeport: 32527
    ingresshttpsnodeport: 30139
    controlplanenodeport: 30968
    addonsnodeport: 31405
  # Specify the already-existing partition and credentials to use with F5
  # bigip:
    # To re-use credentials across clusters we recommend using YAML node anchors.
    # See https://yaml.org/spec/1.2/spec.html#id2785586
    #credentials:
    #  address: "172.16.10.4"
    #  username: "${f5_user}"
    #  password: "${f5_pass}"
    #partition: "admin-cluster"
    # # Optionally specify a pool name if using SNAT
    # snatpoolname: ""
  # The VIPs to use for load balancing
  vips:
    # Used to connect to the Kubernetes API
    controlplanevip: "10.0.11.1"
    # Shared by all services for ingress traffic
    ingressvip: "10.0.11.2"
    # # Used for admin cluster addons (needed for multi cluster features). Must be the same
    # # across clusters
    addonsvip: "10.0.11.3"
  # The Kubernetes service CIDR range for the cluster. Must not overlap with the pod
  # CIDR range
  serviceiprange: 10.96.232.0/24
  # The Kubernetes pod CIDR range for the cluster. Must not overlap with the service
  # CIDR range
  podiprange: 192.168.0.0/16
# Specify settings when deploying a new user cluster. Used both with a fresh deployment
# or when adding a new cluster to an existing deployment.
usercluster:
  # In-Cluster vCenter configuration
  vcenter:
    # If specified it overwrites the network field in global vcenter configuration
    network: ""
  # # The absolute or relative path to the yaml file to use for static IP allocation.
  # # Do not include if using DHCP
  ipblockfilepath: "/home/ubuntu/uc1-static.yaml"
  # # Specify pre-defined nodeports if using "manual" load balancer mode
  manuallbspec:
    ingresshttpnodeport: 30243
    ingresshttpsnodeport: 30879
    controlplanenodeport: 30562
    addonsnodeport: 0
  # Specify the already-existing partition and credentials to use with F5
  # bigip:
    # To re-use credentials across clusters we recommend using YAML node anchors.
    # See https://yaml.org/spec/1.2/spec.html#id2785586
    #credentials:
    #  address: "172.16.10.4"
    #  username: "${f5_user}"
    #  password: "${f5_pass}"
    #partition: "user-cluster1"
    # # Optionally specify a pool name if using SNAT
    # snatpoolname: ""
  # The VIPs to use for load balancing
  vips:
    # Used to connect to the Kubernetes API
    controlplanevip: "10.0.11.4"
    # Shared by all services for ingress traffic
    ingressvip: "10.0.11.5"
    # # Used for admin cluster addons (needed for multi cluster features). Must be the same
    # # across clusters
    # addonsvip: ""
  # A unique name for this cluster
  clustername: "user-cluster1"
  # User cluster master nodes must have either 1 or 3 replicas
  masternode:
    cpus: 4
    memorymb: 8192
    # How many machines of this type to deploy
    replicas: 1
  # The number of worker nodes to deploy and their size. Min. 2 replicas
  workernode:
    cpus: 4
    memorymb: 8192
    # How many machines of this type to deploy
    replicas: 3
  # The Kubernetes service CIDR range for the cluster
  serviceiprange: 10.96.0.0/12
  # The Kubernetes pod CIDR range for the cluster
  podiprange: 192.168.0.0/16
  # # Uncomment this section to use OIDC authentication
  # oidc:
  #   issuerurl: ""
  #   kubectlredirecturl: ""
  #   clientid: ""
  #   clientsecret: ""
  #   username: ""
  #   usernameprefix: ""
  #   group: ""
  #   groupprefix: ""
  #   scopes: ""
  #   extraparams: ""
  #   # Set value to string "true" or "false"
  #   usehttpproxy: ""
  #   # # The absolute or relative path to the CA file (optional)
  #   # capath: ""
  # # Optionally provide an additional serving certificate for the API server
  # sni:
  #   certpath: ""
  #   keypath: ""
# Which load balancer mode to use "Manual" or "Integrated"
lbmode: Manual
# Specify which GCP project to connect your GKE clusters to
gkeconnect:
  projectid: "${gcp_project}"
  # The absolute or relative path to the key file for a GCP service account used to
  # register the cluster
  registerserviceaccountkeypath: "/home/ubuntu/release-reader-key.json"
  # The absolute or relative path to the key file for a GCP service account used by
  # the GKE connect agent
  agentserviceaccountkeypath: "/home/ubuntu/release-reader-key.json"
# Specify which GCP project to connect your logs and metrics to
stackdriver:
  projectid: "${gcp_project}"
  # A GCP region where you would like to store logs and metrics for this cluster.
  clusterlocation: "us-central1"
  enablevpc: false
  # The absolute or relative path to the key file for a GCP service account used to
  # send logs and metrics from the cluster
  serviceaccountkeypath: "/home/ubuntu/release-reader-key.json"
# # Optionally use a private Docker registry to host GKE images
# privateregistryconfig:
#   # Do not include the scheme with your registry address
#   credentials:
#     address: ""
#     username: ""
#     password: ""
#   # The absolute or relative path to the CA certificate for this registry
#   cacertpath: ""
# The absolute or relative path to the GCP service account key that will be used to
# pull GKE images
gcrkeypath: "/home/ubuntu/release-reader-key.json"
