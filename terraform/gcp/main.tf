terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# Create Project
resource "google_project" "fspin" {
  name            = "${var.project_id}"
  project_id      = "${var.project_id}"
  billing_account = "${var.billing_id}"
}

# Enable GCE - Builder VMs, Compute for GKE
resource "google_project_service" "fspin-gce" {
  project = "${google_project.fspin.project_id}"
  service = "compute.googleapis.com"
}

# Enable GCS - Results Storage
resource "google_project_service" "fspin-gcs" {
  project = "${google_project.fspin.project_id}"
  service = "storage.googleapis.com"
}

# Enable GKE - Kubernetes Cluster
resource "google_project_service" "fspin-gke" {
  project = "${google_project_service.fspin-gce.project}"
  service = "container.googleapis.com"
}

# Enable DNS - Dynamic DNS for k8s Resources
resource "google_project_service" "fspin-dns" {
  project = "${google_project.fspin.project_id}"
  service = "dns.googleapis.com"
}
