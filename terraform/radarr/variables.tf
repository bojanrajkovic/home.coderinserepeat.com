variable "radarr_host" {
  type        = string
  description = "The hostname at which to expose the Radarr deployment"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "radarr"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Radarr."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Radarr's data volume."
}

variable "host_volumes" {
  type        = map(string)
  description = "The host volumes to mount into Radarr's container."
}
