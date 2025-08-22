# /Mid-Level/TF-M-2/solution_secrets.tf
# Terraform configuration for Secret Manager
# defines provider, secret resource and secret version

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# the secret resource
resource "google_secret_manager_secret" "my_secret" {
  secret_id = var.secret_id
  replication {
    auto {}
  }
}


# a secret version with the value
resource "google_secret_manager_secret_version" "my_secret_version" {
  secret      = google_secret_manager_secret.my_secret.id
  secret_data = var.secret_value
}