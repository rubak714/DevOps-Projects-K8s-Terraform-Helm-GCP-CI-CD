# /Mid-Level/TF-M-2/variables.tf
# input variables for Secret Manager configuration
# includes project_id, region, secret_id and secret_value

variable "project_id" {
  description = "GCP Project ID where the secret will be created"
  type        = string
}

variable "region" {
  description = "Region for resources"
  type        = string
  default     = "europe-west1"
}

variable "secret_id" {
  description = "The name of the secret"
  type        = string
  default     = "tf-m-2-demo-secret"
}

variable "secret_value" {
  description = "The secret value (for demo purposes only > should not be hardcoded in production)"
  type        = string
  default     = "my-super-secret-value" # Not recommended in production
}