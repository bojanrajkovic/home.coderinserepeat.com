variable "sabnzbd_host" {
  type        = string
  description = "The hostname at which to expose the SABnzbd deployment"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "sabnzbd"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to SABnzbd."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating SABnzbd's data volume."
}

variable "host_volumes" {
  type        = map(string)
  description = "The host volumes to mount into SABnzbd's container."
}

variable "airvpn_credentials_secret" {
  type        = string
  description = "The name of the secret in which AirVPN credentials can be found."
}

variable "airvpn_credentials_1password_vault_item_id" {
  type        = string
  sensitive   = true
  description = "The 1Password item ID to load AirVPN credentials from."
}
