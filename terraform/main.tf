variable "region" {
  type        = string
  description = "The region within to launch the cluster."
}

variable "project_prefix" {
  type        = string
  description = "The project name prefix to create/manage."
}

variable "billing_id" {
  type        = string
  description = "The billing ID to charge resources against."
}
