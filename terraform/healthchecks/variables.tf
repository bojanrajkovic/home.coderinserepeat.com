variable "healthchecks_host" {
  type        = string
  description = "The hostname at which to expose the Healthchecks.io deployment"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "healthchecks"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the data volume to create via a PVC binding."
}

variable "data_volume_size" {
  type        = string
  description = "The size of the data volume to allocate to Healthchecks.io."
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Healthchecks.io's data volume."
}

variable "pushover_api_key" {
  type        = string
  sensitive   = true
  description = "The Pushover API key."
}

variable "pushover_subscription_url" {
  type        = string
  sensitive   = true
  description = "The Pushover Subscription URL."
}
