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

# Enable GCE
resource "google_project_service" "fspin-gce" {
  project = "${google_project.fspin.project_id}"
  service = "container.googleapis.com"
}

# Enable GKE
resource "google_project_service" "fspin-gke" {
  project = "${google_project.fspin.project_id}"
  service = "container.googleapis.com"
}

# Enable DNS
resource "google_project_service" "fspin-dns" {
  project = "${google_project.fspin.project_id}"
  service = "dns.googleapis.com"
}
