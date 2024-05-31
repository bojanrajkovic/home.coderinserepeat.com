variable "omada_host" {
  type        = string
  description = "Hostname to expose the Omada controller deployment at"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "omada"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Omada's configuration."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Omada's data volume."
}

variable "logs_volume_name" {
  type        = string
  description = "The name of the logs volume to create via a PVC binding."
}

variable "logs_volume_size" {
  type        = string
  description = "The size of the logs volume to allocate to Omada's logs"
}

variable "logs_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Omada's logs volume."
}
