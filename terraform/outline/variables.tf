variable "namespace_name" {
  type        = string
  description = "The namespace to deploy Outline components into"
  default     = "outline"
}

variable "data_volume_name" {
  type        = string
  description = "The name of the persistent volume claim for Outline data"
  default     = "outline-data"
}

variable "data_volume_size" {
  type        = string
  description = "The size of the persistent volume claim for Outline data"
  default     = "100Gi"
}

variable "data_volume_storage_class" {
  type        = string
  description = "The storage class for the persistent volume claim for Outline data"
  default     = "zfs-durable"
}

variable "outline_host" {
  type        = string
  description = "The hostname for the Outline server"
  default     = "outline.services.coderinserepeat.com"
}

variable "secret_key" {
  type        = string
  sensitive   = true
  description = "The secret key for the Outline installation"
}

variable "utils_key" {
  type        = string
  sensitive   = true
  description = "The secret key for the Outline installation"
}

variable "google_client_id" {
  type        = string
  sensitive   = true
  description = "The Google OAuth client ID for the Outline installation"
}

variable "google_client_secret" {
  type        = string
  sensitive   = true
  description = "The Google OAuth client secret for the Outline installation"
}

variable "postgres_hostname" {
  type        = string
  description = "The hostname of the PostgreSQL database for Outline"
}
