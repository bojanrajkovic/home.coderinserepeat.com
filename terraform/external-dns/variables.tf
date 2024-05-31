variable "namespace" {
  type        = string
  description = "The namespace to deploy external-dns into."
  default     = "external-dns"
}

variable "root_zone" {
  type        = string
  description = "Root zone for all external-dns published things."
  default     = "services.coderinserepeat.com"
}

variable "external_dns_iam_user_name" {
  type        = string
  description = "Name for the IAM user to create to give external-dns Route53 privileges."
  default     = "external_dns"
}
