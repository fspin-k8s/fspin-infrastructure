# Add Mirror Storage
resource "google_compute_disk" "fspin-mirror" {
  name    = "fspin-mirror-storage"
  project = "${google_project_service.fspin-gce.project}"
  zone    = var.zone
  size    = "300"
  type    = "pd-standard"
}
