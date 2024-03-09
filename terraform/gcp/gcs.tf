# Add Regional Build Results Storage
resource "google_storage_bucket" "fspin-build-results" {
  name          = "${google_project_service.fspin-gcs.project}-fspin-build-results"
  project       = "${google_project_service.fspin-gcs.project}"
  location      = "${var.region}"
  force_destroy = true
  storage_class = "REGIONAL"
}
