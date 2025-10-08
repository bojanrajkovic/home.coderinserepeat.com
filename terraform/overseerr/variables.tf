variable "overseerr_host" {
  type        = string
  description = "The hostname at which to expose the Overseerr deployment"
}

variable "overseerr_tailscale_funnel_host" {
  type        = string
  description = "The Tailscale hostname for public Funnel access"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "overseerr"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Overseerr."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Overseerr's data volume."
}
