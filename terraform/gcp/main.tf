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
  name            = "Fspin Resources"
  project_id      = "${var.project_id}"
  billing_account = "${var.billing_id}"
}

# Enable GKE
resource "google_project_service" "fspin" {
  project = "${google_project.fspin.project_id}"
  service = "container.googleapis.com"
}
