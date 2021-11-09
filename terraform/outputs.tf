output "region" {
  value       = var.region
  description = "GCP Region"
}

output "project" {
  value       = google_project.fspin.project_id
  description = "GCP Project"
}

output "cluster_name" {
  value       = local.cluster_name
  description = "GKE Cluster Name"
}
