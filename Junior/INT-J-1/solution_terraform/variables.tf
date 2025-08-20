variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region (for provider)"
  default     = "europe-west3" # Frankfurt
}

variable "bucket_location" {
  type        = string
  description = "GCS location - multi-region like EU or a region like europe-west3"
  default     = "EU"
}

variable "greeting_message" {
  type        = string
  description = "Text content to store in config/settings.txt"
  default     = "Hello from Terraform!"
}