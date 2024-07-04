variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "icloud-backups"
}

variable "icloud_pd_host_volumes" {
  type        = map(string)
  description = "The host volumes to mount into icloud-pd's container"
}

variable "icloud_password_secret" {
  type        = string
  description = "Secret name for the iCloud password"
}

variable "icloud_password_1password_vault_item_id" {
  type        = string
  sensitive   = true
  description = "The 1Password vault item ID for the iCloud password"
}
