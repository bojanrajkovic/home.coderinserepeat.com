variable "namespace_name" {
  type        = string
  default     = "snmp-exporter"
  description = "Namespace to deploy snmp-exporter components to"
}

variable "scrape_targets" {
  type        = list(string)
  description = "The list of targets to scrape SNMP from"
}

variable "scrape_modules" {
  type        = list(string)
  description = "The list of SNMP modules to configure for scraping"
  default     = ["if_mib", "tplink-ddm", "eap", "system"]
}

variable "scrape_target_to_device_name_map" {
  type        = map(string)
  description = "Mapping of scrape target IPs to human-readable device names"
  default     = {}
}
