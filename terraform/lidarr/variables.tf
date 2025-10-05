variable "lidarr_host" {
  type        = string
  description = "The hostname at which to expose the Lidarr deployment"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "lidarr"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Lidarr."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Lidarr's data volume."
}

variable "music_host_path" {
  type        = string
  description = "The host path to mount as /music in the Lidarr container."
}

variable "downloads_host_path" {
  type        = string
  description = "The host path to mount as /downloads in the Lidarr container."
}
