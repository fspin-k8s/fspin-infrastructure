# Enable GKE
resource "google_project_service" "fspin" {
  project = "${google_project.fspin.project_id}"
  service = "container.googleapis.com"
}

# GKE Autopilot Stable Cluster
resource "google_container_cluster" "fspin" {
  name             = var.cluster_name
  location         = var.region
  project          = "${google_project.fspin.project_id}"
  enable_autopilot = true
  release_channel {
    channel        = "STABLE"
  }
  depends_on = [
    google_project_service.fspin,
  ]
}
