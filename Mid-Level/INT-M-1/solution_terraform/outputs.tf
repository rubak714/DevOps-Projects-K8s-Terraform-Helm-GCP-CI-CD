output "cluster_name" {
  value = module.gke.name
}

output "secret_name" {
  value = google_secret_manager_secret.api_key_secret.secret_id
}
