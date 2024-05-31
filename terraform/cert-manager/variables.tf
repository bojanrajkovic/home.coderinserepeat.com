variable "acme_email" {
  type        = string
  description = "Email address to use for the ACME server registration."
}

variable "namespace" {
  type        = string
  description = "The namespace to deploy all Kubernetes objects into."
  default     = "cert-manager"
}

variable "services_domain" {
  type        = string
  description = "The domain to put ACME challenges under."
}
