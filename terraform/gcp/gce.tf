resource "google_compute_disk" "fspin-mirror" {
  name    = "fspin-mirror-storage"
  project = "${google_project.fspin.name}"
  zone    = var.zone
  size    = "300"
  type    = "pd-standard"
}
