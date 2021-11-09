variable "region" {
  type        = string
  description = "The region within to launch the cluster."
}

variable "zone" {
  type        = string
  description = "The zone within to put resources."
}

variable "project_prefix" {
  type        = string
  description = "The project name prefix to create/manage."
}

variable "billing_id" {
  type        = string
  description = "The billing ID to charge resources against."
}

locals {
  region         = var.region
  zone           = var.zone
  billing_id     = var.billing_id
  project_id     = "${var.project_prefix}-fspin-resources"
  cluster_name   = "${local.project_id}-gke-cluster"
}
