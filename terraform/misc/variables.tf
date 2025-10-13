variable "system_host" {
  type        = string
  description = "Hostname of system to modify system units/files on"
}

variable "system_username" {
  type        = string
  description = "The username to log in as"
}

variable "z2m_host" {
  type        = string
  description = "The hostname of the Z2M machine"
}

variable "z2m_url" {
  type        = string
  description = "The URL to expose the Z2M ingress at"
}
