variable "ipmi_username" {
  type        = string
  description = "IPMI remote scrape username"
}

variable "ipmi_password" {
  type        = string
  sensitive   = true
  description = "IPMI remote scrape password"
}

variable "namespace_name" {
  type        = string
  default     = "ipmi-exporter"
  description = "Namespace to deploy ipmi-exporter components to"
}

variable "scrape_targets" {
  type        = list(string)
  description = "The list of targets to scrape IPMI from"
}
