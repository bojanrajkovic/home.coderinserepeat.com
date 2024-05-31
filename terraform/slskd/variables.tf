variable "soulseek_host" {
  type        = string
  description = "Hostname to expose the Soulseek deployment at"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "slskd"
}

variable "config_volume_name" {
  type        = string
  description = "The name of the config volume to create via a PVC binding."
}

variable "config_volume_size" {
  type        = string
  description = "The size of the config volume to allocate to Soulseek's configuration."
}

variable "config_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Soulseek's config volume."
}

variable "host_volumes" {
  type        = map(string)
  description = "Host volumes to mount into Soulseek's container."
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

variable "gluetun_configuration" {
  type        = map(string)
  sensitive   = true
  description = "The Gluetun configuration for VPN setup."
}
