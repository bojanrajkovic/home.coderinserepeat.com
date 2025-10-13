variable "postgres_hostname" {
  type        = string
  description = "Hostname for the Postgres database that HA's recorder will connect to"
}

variable "namespace_name" {
  type        = string
  description = "The namespace to deploy Home Assistant components into"
  default     = "homeassistant"
}
