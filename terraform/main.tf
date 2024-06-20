terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
  required_version = "~> 1.9"
}

# Provider is configured using environment variables: GOOGLE_REGION, GOOGLE_PROJECT, GOOGLE_CREDENTIALS.
# This can be set statically, if preferred. See docs for details.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#full-reference
provider "google" {}

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
