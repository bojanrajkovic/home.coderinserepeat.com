variable "sonarr_host" {
  type        = string
  description = "The hostname at which to expose the Sonarr deployment"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "sonarr"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Sonarr."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Sonarr's data volume."
}

variable "host_volumes" {
  type        = map(string)
  description = "The host volumes to mount into Sonarr's container."
}
