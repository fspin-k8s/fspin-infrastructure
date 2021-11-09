terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.6"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.3"
    }
  }
  required_version = "~> 1.0.10"
}

# Provider is configured using environment variables: GOOGLE_REGION, GOOGLE_PROJECT, GOOGLE_CREDENTIALS.
# This can be set statically, if preferred. See docs for details.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#full-reference
provider "google" {}

## Configure kubernetes provider with Oauth2 access token.
## https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
## This fetches a new token, which will expire in 1 hour.
#data "google_client_config" "fspin" {
#  depends_on = [module.k8s]
#}
#
## Defer reading the cluster data until the GKE cluster exists.
#data "google_container_cluster" "fspin" {
#  name = local.cluster_name
#  depends_on = [module.k8s]
#}
#
#provider "kubernetes" {
#  host  = "https://${data.google_container_cluster.fspin.endpoint}"
#  token = data.google_client_config.fspin.access_token
#  cluster_ca_certificate = base64decode(
#    data.google_container_cluster.fspin.master_auth[0].cluster_ca_certificate,
#  )
#}
#
#provider "helm" {
#  kubernetes {
#    host  = "https://${data.google_container_cluster.fspin.endpoint}"
#    token = data.google_client_config.fspin.access_token
#    cluster_ca_certificate = base64decode(
#      data.google_container_cluster.fspin.master_auth[0].cluster_ca_certificate,
#    )
#  }
#}

module "gcp" {
  source         = "./gcp"
  region         = local.region
  zone           = local.zone
  billing_id     = local.billing_id
  project_id     = local.project_id
  cluster_name   = local.cluster_name
}

module "k8s" {
  depends_on       = [module.gcp]
  source           = "./k8s"
  region         = local.region
  billing_id     = local.billing_id
  project_id     = local.project_id
  cluster_name   = local.cluster_name
}
