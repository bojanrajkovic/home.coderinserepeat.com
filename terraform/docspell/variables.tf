variable "docspell_host" {
  type        = string
  description = "Hostname that Docspell will be available at after deployment."
}

variable "docspell_configuration_volume" {
  type        = string
  description = "The name of Docspell's configuration volume."
  default     = "docspell"
}

variable "docspell_configuration_volume_size" {
  type        = string
  description = "The size of the PVC that should be created for Docspell's configuration."
  default     = "1Gi"
}

variable "solr_data_volume" {
  type        = string
  description = "The name of Solr's data volume."
  default     = "solr"
}

variable "solr_volume_size" {
  type        = string
  description = "The size of the PVC that should be created for Solr's data."
  default     = "1Gi"
}

variable "docspell_data_volume" {
  type        = string
  description = "The name of Docspell's data volume in the deployment configuration."
}

variable "docspell_data_volume_size" {
  type        = string
  description = "The size of the PVC that should be created for Docspell-managed documents."
  default     = "10Gi"
}

variable "namespace" {
  type        = string
  description = "The namespace to deploy Docspell components into."
  default     = "docspell"
}

variable "volume_storage_class" {
  type        = string
  description = "The storage class to use for PVCs."
  default     = "zfs-durable"
}
