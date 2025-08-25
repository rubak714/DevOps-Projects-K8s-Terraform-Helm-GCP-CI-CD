module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 30.0"

  project_id = var.project_id
  name       = "int-m-1-gke-${random_string.suffix.result}"  # <— unique

  regional = false
  zones    = [var.zone]

  network    = google_compute_network.gke_network.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  ip_range_pods     = "pods-${random_string.suffix.result}"
  ip_range_services = "services-${random_string.suffix.result}"

  create_service_account = false
  service_account        = "int-m-1@stable-healer-418019.iam.gserviceaccount.com"

  node_pools = [
    {
      name         = "default-node-pool"
      machine_type = var.machine_type
      disk_size_gb = 30
      min_count    = 1
      max_count    = 3
    }
  ]
}
