output "project" {
  value       = local.project_id
  description = "GCP Project"
}

output "region" {
  value       = var.region
  description = "GCP Region"
}

output "zone" {
  value       = local.project_id
  description = "GCP Project"
}

output "cluster_name" {
  value       = local.cluster_name
  description = "GKE Cluster Name"
}
