resource "google_compute_disk" "fspin-mirror" {
  name    = "fspin-mirror-storage"
  project = var.project_id
  zone    = var.zone
  size    = "300"
  type    = "pd-standard"
}
