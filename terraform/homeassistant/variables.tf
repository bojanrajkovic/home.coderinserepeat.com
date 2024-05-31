variable "postgres_hostname" {
  type        = string
  description = "Hostname for the Postgres database that HA's recorder will connect to"
}

variable "postgres_cert_secret_name" {
  type        = string
  description = "Name of the secret to store the TLS certificate in"
  default     = "recorder-postgres-server-cert"
}

variable "namespace_name" {
  type        = string
  description = "The namespace to deploy Home Assistant components into"
  default     = "homeassistant"
}
