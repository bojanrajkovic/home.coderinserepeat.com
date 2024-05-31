variable "namespace_name" {
  type        = string
  description = "The namespace to deploy Loki and associated components into"
  default     = "loki"
}

variable "loki_hostname" {
  type        = string
  description = "The hostname to expose the Loki server at"
}
