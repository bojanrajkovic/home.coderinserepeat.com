variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything into."
  default     = "the-lounge"
}

variable "lounge_host" {
  type        = string
  description = "The hostname to expose the The Lounge deployment at."
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to The Lounge's configuration."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating The Lounge's data volume."
}
