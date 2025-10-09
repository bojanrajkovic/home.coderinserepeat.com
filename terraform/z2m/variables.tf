variable "namespace_name" {
  type        = string
  default     = "z2m"
  description = "Namespace to deploy z2m components to"
}

variable "mqtt_server" {
  type        = string
  description = "MQTT server URL (e.g., mqtt://mosquitto.mqtt.svc.cluster.local:1883)"
}

variable "serial_port" {
  type        = string
  description = "Serial port for Zigbee adapter (network or USB)"
}

variable "storage_size" {
  type        = string
  default     = "10Gi"
  description = "Storage size for zigbee2mqtt data"
}

variable "storage_class" {
  type        = string
  default     = "zfs-durable"
  description = "Storage class for zigbee2mqtt data volume"
}

variable "z2m_host" {
  type        = string
  description = "Hostname for zigbee2mqtt web interface ingress"
}

variable "timezone" {
  type        = string
  default     = "America/New_York"
  description = "Timezone for zigbee2mqtt"
}

variable "log_level" {
  type        = string
  default     = "info"
  description = "Log level for zigbee2mqtt (debug, info, warn, error)"
}

variable "permit_join" {
  type        = bool
  default     = false
  description = "Allow new devices to join the Zigbee network"
}

variable "mqtt_username" {
  description = "MQTT username for Zigbee2mqtt connection"
  type        = string
}

variable "mqtt_password" {
  description = "MQTT password for Zigbee2mqtt connection"
  type        = string
  sensitive   = true
}
