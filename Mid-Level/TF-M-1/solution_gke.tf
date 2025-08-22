# /Mid-Level/TF-M-1/solution_gke.tf
# GKE cluster with required VPC/secondary ranges

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Minimal VPC and subnetwork with secondary ranges for GKE (required by the module)
resource "google_compute_network" "gke" {
  name                    = "tf-m-1-net"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke" {
  name          = "tf-m-1-subnet"
  region        = var.region
  network       = google_compute_network.gke.id
  ip_cidr_range = var.subnet_cidr

  secondary_ip_range = [
    {
      range_name    = "pods"
      ip_cidr_range = var.pods_cidr
    },
    {
      range_name    = "services"
      ip_cidr_range = var.services_cidr
    }
  ]
}

# GKE cluster using the official terraform-google-modules/kubernetes-engine/google module
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 30.0"

  project_id = var.project_id
  name       = "tf-m-1-gke"

  # ZONAL instead of regional
  regional = false
  zones    = ["europe-west1-b"]  

  deletion_protection = false

  # VPC native
  network           = google_compute_network.gke.name
  subnetwork        = google_compute_subnetwork.gke.name
  ip_range_pods     = "pods"
  ip_range_services = "services"

  # Node pool settings (smaller disk, standard PD)
  initial_node_count = var.initial_node_count
  node_pools = [
    {
      name          = "default-node-pool"
      machine_type  = var.machine_type
      disk_type     = "pd-standard"
      disk_size_gb  = 30
      min_count     = 1
      max_count     = 3
    }
  ]
}

