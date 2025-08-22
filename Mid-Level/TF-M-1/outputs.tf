# /Mid-Level/TF-M-1/outputs.tf
# Outputs from the GKE module

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.name
}

output "cluster_region" {
  description = "Region where the cluster is deployed"
  value       = module.gke.region
}

output "endpoint" {
  description = "Cluster endpoint"
  value       = module.gke.endpoint
}

output "node_pools_names" {
  description = "Names of the node pools"
  value       = module.gke.node_pools_names
}

