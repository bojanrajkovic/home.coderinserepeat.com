resource "grafana_folder" "folders" {
  for_each = toset([
    "Compute",
    "Networking",
    "Cluster Components",
    "House Infrastructure",
    "Smart Home",
    "Loki"
  ])
  title = each.value
}

resource "grafana_dashboard" "dashboards" {
  depends_on  = [grafana_folder.folders]
  for_each    = fileset("${path.module}/dashboards", "*/*.json")
  folder      = grafana_folder.folders[dirname(each.value)].id
  config_json = file("${path.module}/dashboards/${each.value}")
}

import {
  to = grafana_dashboard.dashboards["Networking/metallb.json"]
  id = "nvTWlxQGz"
}

import {
  to = grafana_folder.folders["Compute"]
  id = "ednigb8kgz7cwb"
}

import {
  to = grafana_folder.folders["Networking"]
  id = "bdnii2plylh4wf"
}
