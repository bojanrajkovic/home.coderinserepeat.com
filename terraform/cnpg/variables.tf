variable "namespace" {
  type        = string
  description = "The namespace to install the CNPG operator Helm chart into."
  default     = "cnpg"
}

variable "chart_version" {
  type        = string
  description = "The chart version to install."
  default     = "v0.21.4"
}
