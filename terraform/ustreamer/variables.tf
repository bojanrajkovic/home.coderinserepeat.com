variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything into."
  default     = "ustreamer"
}

variable "ustreamer_host" {
  type        = string
  description = "The hostname to expose the ustreamer deployment at."
}
