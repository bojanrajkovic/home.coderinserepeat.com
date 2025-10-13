variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy Vector into."
  default     = "vector"
}

variable "vector_hostname" {
  type        = string
  description = "The hostname to expose the Vector syslog service at for external-dns."
}

variable "loki_endpoint" {
  type        = string
  description = "The endpoint for the Loki service."
}
