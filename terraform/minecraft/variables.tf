variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything into."
  default     = "minecraft"
}

variable "minecraft_host" {
  type        = string
  description = "The hostname to expose the Minecraft server deployment at."
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Minecraft's configuration and data."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Minecraft's data volume."
}
