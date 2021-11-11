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

resource "random_id" "project_name" {
  byte_length = 5
}

locals {
  region         = var.region
  zone           = var.zone
  billing_id     = var.billing_id
  project_id     = "${var.project_prefix}-${random_id.project_name.hex}"
  cluster_name   = "${local.project_id}-gke-cluster"
}
