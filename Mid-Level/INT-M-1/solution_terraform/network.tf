resource "google_compute_network" "gke_network" {
  name                    = "gke-vpc-${random_string.suffix.result}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet-${random_string.suffix.result}"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.gke_network.id

  secondary_ip_range = [
    {
      range_name    = "pods-${random_string.suffix.result}"
      ip_cidr_range = "10.4.0.0/14"
    },
    {
      range_name    = "services-${random_string.suffix.result}"
      ip_cidr_range = "10.8.0.0/20"
    }
  ]
}
