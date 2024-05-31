variable "configuration_volumes" {
  type        = set(string)
  description = "Configuration volumes that need to be mounted for Backrest's configuration."
}

variable "backup_volumes" {
  type        = set(string)
  description = "Volumes that are explicitly mounted for backup via Backrest."
}

variable "backrest_hostname" {
  type        = string
  description = "The hostname at which the Backrest UI should be available."
}

variable "namespace_name" {
  type        = string
  description = "The namespace name to create all Kubernetes objects in."
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Backrest's configuration."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Backrest's data volume."
}
