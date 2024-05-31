variable "octoprint_host" {
  type        = string
  description = "Hostname to expose the Octoprint deployment at"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "octoprint"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Octoprint."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Octoprint's data volume."
}
