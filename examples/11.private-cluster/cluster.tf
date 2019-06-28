provider "google" {
  # credentials = "${file("~/gcp_sa.json")}"
  project     = "${var.project_id}"
}

data "google_container_engine_versions" "region" {
  zone = "${var.cluster_zone}"
}

# data "google_container_cluster" "primary" {
#   name = "${var.cluster_name}"
#   zone = "${var.cluster_zone}"
# }

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.subnetwork}"
  ip_cidr_range = "${var.subnet_cidr}"
  region        = "${var.region}"
  network       = "${var.network}"
  private_ip_google_access = true
  secondary_ip_range = [
    {
      range_name    = "${var.cluster_name}-pods"
      ip_cidr_range = "${var.pods_range}"
    },
    {
      range_name    = "${var.cluster_name}-services"
      ip_cidr_range = "${var.services_range}"
    },
  ]
}

resource "google_container_cluster" "primary" {
  name = "${var.cluster_name}"

  zone = "${var.cluster_zone}"
  # region                  = "${var.region}"      # uncomment this to create a regional cluster

  enable_kubernetes_alpha = "${var.enable_kubernetes_alpha}"
  enable_legacy_abac      = "${var.enable_legacy_abac}"

  # initial_node_count      = "${var.initial_node_count}"      # being set by node_pool

  # remove_default_node_pool = "${var.remove_default_node_pool}
  network                  = "${var.network}"
  subnetwork               = "${google_compute_subnetwork.subnet.name}"
  min_master_version       = "${data.google_container_engine_versions.region.latest_node_version}"
  logging_service          = "${var.logging_service}"
  monitoring_service       = "${var.monitoring_service}"
  private_cluster          = "${var.private_cluster}"
  master_ipv4_cidr_block   = "${var.master_ipv4_cidr_block}"

  # Configuration for cluster IP allocation. 
  # As of now, only pre-allocated subnetworks (custom type with secondary ranges) are supported. 
  # This will activate IP aliases.

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.cluster_name}-pods"
    services_secondary_range_name = "${var.cluster_name}-services"
  }

  # Control Plane Security: Disable authorization and certificate issue
  # If this block is provided and both username and password are empty, basic authentication will be disabled.

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }

    kubernetes_dashboard {
      disabled = true
    }

    network_policy_config {
      disabled = false
    }
  }
  master_authorized_networks_config {
    cidr_blocks = [
      {
        cidr_block = "0.0.0.0/0"
      },
    ]
  }
  maintenance_policy {
    daily_maintenance_window {
      start_time = "${var.maintenance_window_start_time}"
    }
  }
  
  # lifecycle {
  #   ignore_changes = ["node_pool"]
  # }

  node_pool {
    name = "default-pool"
    node_count = "${var.initial_node_count}"

    autoscaling {
      min_node_count = "${var.autoscaling_min_node}"
      max_node_count = "${var.autoscaling_max_node}"
    }

    management {
      auto_repair  = "${var.auto_repair}"
      auto_upgrade = "${var.auto_upgrade}"
    }

    node_config {
      image_type   = "${var.image_type}"
      machine_type = "${var.machine_type}"
      preemptible = "${var.preemptible}"

      /* The Kubernetes labels (key/value pairs) to be applied to each node */
      labels {
        #my_key = "my_value"
      }
  
      oauth_scopes = [
        "https://www.googleapis.com/auth/compute",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]

      tags = ["ssh", "no-ip"]
    }
  }
}

/* CLUSTER VARIABLES */

variable "project_id" {
  description = "Google Project Identifier"
  default     = "nmiu-play"
}

variable "region" {
  type    = "string"
  default = "us-central1"
}

variable "subnet_cidr" {
  type    = "string"
  default = "10.50.0.0/16"
}

variable "pods_range" {
  type    = "string"
  default = "10.51.0.0/16"
}

variable "services_range" {
  type    = "string"
  default = "10.52.0.0/16"
}

variable "cluster_zone" {
  description = "Provide single zone to list available cluster versions for. Should match the zone the cluster will be deployed in."
  type        = "string"
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name to describe the GKE cluster."
  default     = "asuka"
}

variable "enable_kubernetes_alpha" {
  description = "Whether to enable Kubernetes Alpha features for this cluster.Note that when this option is enabled, the cluster cannot be upgraded and will be automatically deleted after 30 days."
  default     = "false"
}

variable "enable_legacy_abac" {
  description = "Whether the ABAC authorizer is enabled for this cluster. When enabled, identities in the system, including service accounts, nodes, and controllers, will have statically granted permissions beyond those provided by the RBAC configuration or IAM. Defaults to false"
  default     = "false"
}

variable "remove_default_node_pool" {
  description = "If true, deletes the default node pool upon cluster creation."
  default     = "true"
}

variable "network" {
  description = "This will be set by the networking module call from the main vpc.  The name or self_link of the Google Compute Engine network to which the cluster is connected. "
  default     = "default"
}

variable "subnetwork" {
  description = "This will be set by the networking module call from the main vpc. The name or self_link of the Google Compute Engine subnetwork in which the cluster's instances are launched"
  default     = "gke-clusters"
}

variable "monitoring_service" {
  description = "Options: monitoring.googleapis.com, monitoring.googleapis.com/kubernetes (beta) and none.  The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Google Cloud Monitoring API. "
  type        = "string"
  default     = "monitoring.googleapis.com"
}

variable "logging_service" {
  description = "Available options include logging.googleapis.com, logging.googleapis.com/kubernetes (beta), and none.  The logging service that the cluster should write logs to. "
  type        = "string"
  default     = "logging.googleapis.com"
}

variable "private_cluster" {
  description = "If true, a private cluster will be created, which makes the master inaccessible from the public internet and nodes do not get public IP addresses either"
  default     = "true"
}

variable "master_ipv4_cidr_block" {
  description = "pecifies a private RFC1918 block for the master's VPC. The master range must not overlap with any subnet in your cluster's VPC. The master and your cluster use VPC peering. Must be specified in CIDR notation and must be /28 subnet"
  default     = "172.16.0.16/28"
}

variable "maintenance_window_start_time" {
  description = "Time window specified for daily maintenance operations in RFC3339 format HH:MM”, where HH : [00-23] and MM : [00-59] GMT."
  default     = "04:00"
}

/* NODE POOL Variable Settings */

# variable "node_pool_name" {
#   description = "Name of the node pool"
#   default     = "minions"
# }

variable "initial_node_count" {
  description = "The number of nodes to create in this cluster (not including the Kubernetes master). Must be set if node_pool is not set."
  default     = "3"
}

variable "autoscaling_min_node" {
  description = "Minimum number of nodes in the NodePool. Must be >=1 and <= max_node_count."
  default     = "1"
}

variable "autoscaling_max_node" {
  description = "Maximum number of nodes in the NodePool. Must be >= min_node_count."
  default     = "5"
}

variable "auto_repair" {
  description = " true or false.  Whether the nodes will be automatically repaired."
  default     = "true"
}

variable "auto_upgrade" {
  description = " true or false.  Whether the nodes will be automatically upgraded."
  default     = "true"
}

variable "image_type" {
  description = "https://cloud.google.com/compute/docs/images.The image type to use for this node "
  default     = "cos"
}

variable "machine_type" {
  description = "https://cloud.google.com/compute/docs/machine-types. The name of a Google Compute Engine machine type. Defaults to n1-standard-1"
  default     = "n1-standard-2"
}

variable "preemptible" {
  description = " true or false. Whether the nodes are preemptible"
  default     = "true"
}