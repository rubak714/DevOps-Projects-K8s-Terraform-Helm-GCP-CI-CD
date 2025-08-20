# configuring the Google Cloud provider only for Terraform
# project_id and region come from variables.tf

provider "google" {
  project = var.project_id
  region  = var.region
}

# generating a short random hex string
# this is used to make the bucket name globally unique

resource "random_id" "suffix" {
  byte_length = 4
}

# creating a Google Cloud Storage bucket
# "config" is terraform resource label (local name for referencing)
# the GCS bucket> hold a small text object

resource "google_storage_bucket" "config" {
  name                        = "db-ms-intj1-${random_id.suffix.hex}"
  location                    = var.bucket_location
  force_destroy               = true
}

# creating a single text object (file) inside the bucket with the greeting message
# "settings" is terraform resource label

resource "google_storage_bucket_object" "settings" {
  name    = "config/settings.txt"  # object key inside the bucket
  bucket  = google_storage_bucket.config.name  # attaching the object to the bucket created
  content = var.greeting_message   # content of the object comes from the variable greeting_message
}