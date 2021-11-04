resource "google_project" "fspin" {
  name            = "Fspin Resources"
  project_id      = "${var.project_prefix}-fspin-resources"
  billing_account = "${var.billing_id}"
}
