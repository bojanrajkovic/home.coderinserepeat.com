variable "namespace_name" {
  type        = string
  description = "Namespace to deploy kube-prometheus components into"
  default     = "kube-prometheus"
}

variable "homeassistant_scrape_key" {
  type        = string
  sensitive   = true
  description = "The scrape key for HomeAssistant's Prometheus exporter"
}

variable "grafana_auth_key" {
  type        = string
  sensitive   = true
  description = "Grafana auth key for creating dashboards/folders"
}

variable "homeassistant_scrape_targets" {
  type        = list(string)
  description = "List of HomeAssistant hosts/IPs to scrape"
}

variable "pushover_api_token" {
  type        = string
  sensitive   = true
  description = "Pushover API token for notification sending"
}

variable "pushover_user_key" {
  type        = string
  sensitive   = true
  description = "Pushover user key for notification sending"
}

variable "grafana_host" {
  type        = string
  description = "Grafana hostname to set up ingress for"
}
