# Create Specialized Service Account
resource "google_service_account" "fspin-k8s-nodes" {
  account_id   = "fspin-k8s-nodes"
  display_name = "Fspin GKE Nodes"
  project      = "${google_project_service.fspin-gke.project}"
}

# Bind Policies to Service Account
resource "google_service_account_iam_binding" "fspin-k8s-iam-binding" {
  service_account_id = google_service_account.fspin-k8s-nodes.name
  role               = "roles/iam.serviceAccountUser"
  members            = [
    "serviceAccount:${google_service_account.fspin-k8s-nodes.email}",
  ]
}

# Add Project IAM Permissions
resource "google_project_iam_member" "fspin-k8s-iam-project-member" {
  project = "${google_project_service.fspin-gke.project}"
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.fspin-k8s-nodes.email}"
}

# GKE Stable Cluster
resource "google_container_cluster" "fspin" {
  name                     = var.cluster_name
  location                 = var.zone
  project                  = "${google_project_service.fspin-gke.project}"
  release_channel {
    channel                = "STABLE"
  }
  remove_default_node_pool = true
  initial_node_count       = 1
}

# GKE Node Pool
resource "google_container_node_pool" "fspin-nodes" {
  name               = "fspin-k8s-nodes"
  cluster            = "${google_container_cluster.fspin.name}"
  location           = var.zone
  project            = "${google_project_service.fspin-gke.project}"
  node_count = 1

  autoscaling {
    min_node_count   = 1
    max_node_count   = 3
  }

  node_config {
    machine_type    = "e2-medium"
    service_account = google_service_account.fspin-k8s-nodes.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
