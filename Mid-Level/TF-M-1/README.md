# Terraform

# Task (TF-M-1): Create Standard GKE Cluster

*   **Use Case:** Write Terraform code to create a basic GKE cluster (Standard or Autopilot - your choice) in a specific region. Configure at least the machine type (if Standard) and the initial node count. Use the official Google Terraform module for GKE if possible.
*   **Verification:** Is the code valid? Can it create a functional GKE cluster? Are the parameters applied correctly?
*   **Solution:** Place in: `/Mid-Level/TF-M-1/solution_gke.tf`

---

# *Solutions: TF-M-1 > Basic GKE Cluster with Terraform*

## Task Layout

```
/Mid-Level/TF-M-1/
   │── solution_gke.tf     # main configuration: provider + GKE module
   │── variables.tf        # input variables for project_id, region, machine_type, node count
   │── outputs.tf          # outputs such as cluster name, region, endpoint and node pools
   │── terraform.tfvars
   └── README.md      
```

---

# Step-by-Step Execution

## Parameters Used

- `project_id`         = (required)   > GCP Project ID where cluster created
- `region`             = europe-west1 > Region for the GKE cluster
- `machine_type`       = e2-medium    > Node machine type
- `initial_node_count` = 2            > Initial number of nodes

---

## 1. Prepared the Terraform files

**File:** `solution_gke.tf`

```hcl
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
```

**File:** `variables.tf`

```hcl
# /Mid-Level/TF-M-1/variables.tf
# Input variables for GKE cluster

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region for the cluster"
  type        = string
  default     = "europe-west1"
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "initial_node_count" {
  description = "Initial number of nodes in the pool"
  type        = number
  default     = 2
}

# Networking CIDRs 
variable "subnet_cidr" {
  description = "Primary subnet CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "pods_cidr" {
  description = "Secondary range for pods"
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "Secondary range for services"
  type        = string
  default     = "10.30.0.0/20"
}
```

**File:** `outputs.tf`

```hcl

# /Mid-Level/TF-M-1/outputs.tf
# Outputs from the GKE module

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.name
}

output "cluster_region" {
  description = "Region where the cluster is deployed"
  value       = module.gke.region
}

output "endpoint" {
  description = "Cluster endpoint"
  value       = module.gke.endpoint
}

output "node_pools_names" {
  description = "Names of the node pools"
  value       = module.gke.node_pools_names
}
```

---
                   
## 2. Navigated into the task directory

   ```bash
   cd Mid-Level/TF-M-1
   ```

## 3. Enabled API 

```bash
PROJECT_ID=stable-healer-418019

gcloud config set project ${PROJECT_ID}

# Enable GKE API
gcloud services enable container.googleapis.com
```

## 4. Initialized Terraform

   ```bash
   terraform init # or terraform init -upgrade
   ```

## 5. Validated the configuration

   ```bash
   terraform validate
   ```

## 6. Planned and Applied the configuration to create the GKE cluster

   ```bash
   terraform plan 
   terraform apply -auto-approve
   ```

## 7. Viewed outputs after deployment

```bash
terraform output
```
Outputs: 

- Cluster name
- Cluster region
- Cluster endpoint
- Node pool names

---

## Verification Notes

- `terraform init` ran successfully and downloaded the required providers and modules.
- `terraform validate` confirms the code was valid.
- Running `terraform apply` provisioned a functional GKE cluster inside the specified GCP project.
- The applied parameters (region, machine type, node count) were reflected in the created cluster.
- Outputs confirmed cluster name, region, endpoint and node pool details.

In this way, a functional **GKE Standard cluster** was provisioned in my GCP project with a default node pool configured with the specified machine type and node count.

