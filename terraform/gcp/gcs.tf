# Add Regional Build Results Storage
resource "google_storage_bucket" "fspin-build-results" {
  name          = "${google_project_service.fspin-gce.project}-fspin-build-results"
  project       = "${google_project_service.fspin-gce.project}"
  location      = "${var.region}"
  storage_class = "REGIONAL"
}
