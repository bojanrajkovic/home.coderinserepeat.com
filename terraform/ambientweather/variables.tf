variable "station_mac_address" {
  description = "MAC address of the Ambient Weather station"
  type        = string
  sensitive   = true
}

variable "mqtt_server" {
  description = "MQTT server URL"
  type        = string
  sensitive   = true
}

variable "mqtt_username" {
  description = "MQTT username for authentication"
  type        = string
  sensitive   = true
}

variable "mqtt_password" {
  description = "MQTT password for authentication"
  type        = string
  sensitive   = true
}

variable "namespace_name" {
  description = "Kubernetes namespace for Ambient Weather"
  type        = string
  default     = "ambientweather"
}

variable "ambientweather_host" {
  description = "Host for Ambient Weather Ingress"
  type        = string
}
