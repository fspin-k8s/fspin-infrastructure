terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

resource "google_project" "fspin" {
  name            = "Fspin Resources"
  project_id      = "${var.project_id}"
  billing_account = "${var.billing_id}"
}
