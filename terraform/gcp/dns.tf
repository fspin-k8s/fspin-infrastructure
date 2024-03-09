resource "google_dns_managed_zone" "k8s-fspin-org" {
  name          = "k8s-fspin-org"
  dns_name      = "k8s.fspin.org."
  description   = "k8s Fspin Zone"
  project       = "${google_project_service.fspin-dns.project}"
  force_destroy = true
}
