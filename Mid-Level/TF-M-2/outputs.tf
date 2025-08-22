# /Mid-Level/TF-M-2/outputs.tf
# output values after secret creation
# displays secret name and resource ID

output "secret_name" {
  description = "The name of the created secret"
  value       = google_secret_manager_secret.my_secret.name
}

output "secret_id" {
  description = "The resource ID of the secret"
  value       = google_secret_manager_secret.my_secret.id
}