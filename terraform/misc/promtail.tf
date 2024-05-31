resource "system_folder" "keyrings" {
  path  = "/etc/apt/keyrings"
  user  = "root"
  group = "root"
}

resource "system_file" "grafana_gpg_key" {
  path   = "/etc/apt/keyrings/grafana.gpg"
  source = "./grafana.gpg.key"
  user   = "root"
  group  = "root"
}

resource "system_file" "grafana_sources_list" {
  path    = "/etc/apt/sources.list.d/grafana.list"
  content = "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main"
}

resource "system_packages_apt" "promtail" {
  package {
    name = "promtail"
  }
}

resource "system_service_systemd" "promtail" {
  name    = "promtail"
  status  = "started"
  enabled = true
}

resource "system_file" "promtail" {
  path   = "/etc/promtail/config.yml"
  source = "../../secrets/promtail/promtail.yml"
}

resource "system_folder" "promtail" {
  path = "/var/spool/promtail"
  user = "promtail"
}
