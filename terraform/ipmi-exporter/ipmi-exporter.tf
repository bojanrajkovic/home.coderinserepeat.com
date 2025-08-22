locals {
  ipmi_config = {
    user      = var.ipmi_username
    pass      = var.ipmi_password
    driver    = "LAN_2_0"
    privilege = "operator"
  }
}

resource "kubernetes_namespace_v1" "ipmi_exporter" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "helm_release" "ipmi_exporter" {
  depends_on = [kubernetes_namespace_v1.ipmi_exporter]
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-ipmi-exporter"
  name       = "ipmi-exporter"
  namespace  = var.namespace_name
  version    = "0.6.3"

  set {
    name  = "serviceMonitor.enabled"
    value = false
  }

  set {
    name  = "serviceMonitor.telemetryPath"
    value = "/ipmi"
  }

  set {
    name  = "serviceMonitor.labels.release"
    value = "kube-prometheus"
  }

  dynamic "set" {
    for_each = local.ipmi_config

    content {
      name  = "modules.default.${set.key}"
      value = set.value
    }
  }

  set_list {
    name  = "modules.default.collectors"
    value = ["bmc", "ipmi", "chassis", "sm-lan-mode"]
  }
}

resource "kubernetes_manifest" "ipmi_exporter_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      labels = {
        release = "kube-prometheus"
      }

      name      = "ipmi-exporter-prometheus-ipmi-exporter"
      namespace = var.namespace_name
    }

    spec = {
      endpoints = [{
        path       = "ipmi"
        targetPort = 9290

        params = {
          target = var.scrape_targets
        }
      }]

      jobLabel = "ipmi-exporter-prometheus-ipmi-exporter"

      namespaceSelector = {
        matchNames = [var.namespace_name]
      }

      selector = {
        matchLabels = {
          "app.kubernetes.io/instance" = "ipmi-exporter"
          "app.kubernetes.io/name"     = "prometheus-ipmi-exporter"
        }
      }
    }
  }
}
