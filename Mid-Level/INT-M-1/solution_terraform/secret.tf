# created a secret in Google Secret Manager
resource "google_secret_manager_secret" "api_key_secret" {
  secret_id = "api-key-secret-${random_string.suffix.result}"
  replication { 
    auto {} 
    }
}

