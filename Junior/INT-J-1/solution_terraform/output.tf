output "bucket_name" {
  value = google_storage_bucket.config.name
}

output "settings_url" {
  value = "gs://${google_storage_bucket.config.name}/${google_storage_bucket_object.settings.name}"
}
