variable "namespace_name" {
  type        = string
  default     = "tailscale"
  description = "Namespace to deploy tailscale-operator components to"
}

variable "oauth_credentials_secret" {
  type        = string
  default     = "operator-oauth"
  description = "The name of the secret in which Tailscale OAuth credentials can be found"
}

variable "oauth_credentials_1password_vault_item_id" {
  type        = string
  sensitive   = true
  description = "The 1Password item ID to load Tailscale OAuth credentials from"
}
