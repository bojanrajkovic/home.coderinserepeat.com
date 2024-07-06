variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "icloud-backups"
}

variable "icloud_pd_host_volumes" {
  type        = map(string)
  description = "The host volumes to mount into icloud-pd's container"
}

variable "pd_backup_apple_ids" {
  type = map(string)
  description = "The users whose iCloud Photos to back up"
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