variable "scrutiny_host" {
  type        = string
  description = "Hostname to expose the Scrutiny deployment at"
}

variable "namespace_name" {
  type        = string
  description = "The Kubernetes namespace to deploy everything to"
  default     = "scrutiny"
}

variable "config_volume_name" {
  type        = string
  description = "The name of the config volume to create via a PVC binding."
}

variable "config_volume_size" {
  type        = string
  description = "The size of the config volume to allocate to Scrutiny's configuration."
}

variable "config_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Scrutiny's config volume."
}

variable "influxdb_volume_name" {
  type        = string
  description = "The name of the influxdb volume to create via a PVC binding."
}

variable "influxdb_volume_size" {
  type        = string
  description = "The size of the influxdb volume to allocate to Scrutiny's InfluxDB"
}

variable "influxdb_volume_storage_class" {
  type        = string
  description = "The storage class to use when creating Scrutiny's InfluxDB volume."
}
