terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}


# generating a random hex suffix to ensure bucket name uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# TF-J-1: Create a unique GCS bucket
# Verification:
# - Code is valid (passes terraform validate)
# - Creates a GCS bucket in europe-west3
# - Name is unique via random_id
# - Uses uniform bucket-level access and force_destroy for cleanup

resource "google_storage_bucket" "bucket" {
  name                        = "db-ms-tf-j-1-${random_id.suffix.hex}"
  location                    = "europe-west3"
  uniform_bucket_level_access = true
  force_destroy               = true
}

# TF-J-2: Output the bucket name
# Verification:
# - terraform output bucket_name will display the correct bucket name

output "bucket_name" {
  value       = google_storage_bucket.bucket.name
  description = "Name of the created GCS bucket"
}
