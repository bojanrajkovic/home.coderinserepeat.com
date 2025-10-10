variable "builder_namespace" {
  type        = string
  description = "Namespace for the esphome-fanout-builder deployment"
}

variable "target_namespace" {
  type        = string
  description = "Namespace where ESPHome upload pods will be created"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository containing ESPHome configs (format: owner/repo)"
}

variable "github_branch" {
  type        = string
  description = "Branch to monitor for changes"
}

variable "github_token_1password_vault_item_id" {
  type        = string
  sensitive   = true
  description = "1Password vault item ID for GitHub token"
}

variable "watch_paths" {
  type        = list(string)
  description = "Glob patterns to watch for changes"
}

variable "poll_interval" {
  type        = string
  description = "How often to check for changes"
}

variable "esphome_image" {
  type        = string
  description = "ESPHome docker image to use for uploads"
}

variable "builder_image" {
  type        = string
  description = "ESPHome fanout builder image"
}

variable "log_level" {
  type        = string
  description = "Log level (debug, info, warn, error)"
}
