variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy EMQX into."
  default     = "emqx"
}

variable "emqx_hostname" {
  type        = string
  description = "The hostname to expose the EMQX listeners at for external-dns."
}

variable "emqx_dashboard_hostname" {
  type        = string
  description = "The hostname to expose the EMQX dashboard at for external-dns."
}
