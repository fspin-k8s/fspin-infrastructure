# Add Regional Build Results Storage
resource "google_storage_bucket" "fspin-build-results" {
  name          = "${var.project_id}-fspin-build-results"
  project       = "${var.project_id}"
  location      = "${var.region}"
  storage_class = "REGIONAL"
}
