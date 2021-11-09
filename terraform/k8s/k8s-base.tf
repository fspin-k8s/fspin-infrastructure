# GKE Cluster Service Accounts
resource "kubernetes_service_account" "fspin-dns" {
  metadata {
    name = "fspin-dns"
    namespace = "default"
  }
}

# GKE ClusterRole Bindings
resource "kubernetes_cluster_role_binding" "fspin-dns" {
  metadata {
    name = "fspin-dns"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "fspin-dns"
    namespace = "default"
    api_group = "rbac.authorization.k8s.io"
  }
}
