resource "kubernetes_namespace_v1" "snmp_exporter" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_config_map_v1" "snmp_exporter_config" {
  metadata {
    name      = "snmp-exporter-config"
    namespace = var.namespace_name
  }

  data = {
    "snmp.yml" = file("${path.module}/snmp.yml")
  }

  depends_on = [kubernetes_namespace_v1.snmp_exporter]
}

resource "kubernetes_deployment_v1" "snmp_exporter" {
  metadata {
    name      = "snmp-exporter"
    namespace = var.namespace_name

    labels = {
      app = "snmp-exporter"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "snmp-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "snmp-exporter"
        }
      }

      spec {
        container {
          name  = "snmp-exporter"
          image = "prom/snmp-exporter:v0.29.0@sha256:272ff087c314fb1e384b7ba7e555f020cc0c072fb23f0dc1d1cb51b48067efdc"

          args = [
            "--config.file=/etc/prometheus/snmp.yml",
            "--config.file=/etc/snmp_exporter/snmp.yml"
          ]

          port {
            name           = "http"
            container_port = 9116
            protocol       = "TCP"
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/snmp_exporter"
            read_only  = true
          }

          volume_mount {
            name       = "general-config"
            mount_path = "/etc/prometheus"
            read_only  = true
          }

          liveness_probe {
            http_get {
              path = "/config"
              port = 9116
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/config"
              port = 9116
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map_v1.snmp_exporter_config.metadata[0].name
          }
        }

        volume {
          name = "general-config"

          host_path {
            type = "Directory"
            path = "/etc/prometheus"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_config_map_v1.snmp_exporter_config]
}

resource "kubernetes_service_v1" "snmp_exporter" {
  metadata {
    name      = "snmp-exporter"
    namespace = var.namespace_name

    labels = {
      app = "snmp-exporter"
    }
  }

  spec {
    selector = {
      app = "snmp-exporter"
    }

    port {
      name        = "http"
      port        = 9116
      target_port = 9116
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.snmp_exporter]
}

resource "kubernetes_manifest" "snmp_exporter_scrape_config" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1alpha1"
    kind       = "ScrapeConfig"

    metadata = {
      labels = {
        release = "kube-prometheus"
      }

      name      = "snmp-exporter"
      namespace = var.namespace_name
    }

    spec = {
      staticConfigs = [
        {
          targets = var.scrape_targets
        }
      ]

      metricsPath = "/snmp"

      params = {
        auth   = ["omada"]
        module = var.scrape_modules
      }

      scheme            = "HTTP"
      enableCompression = true

      relabelings = concat([
        {
          sourceLabels = ["__address__"]
          targetLabel  = "__param_target"
        },
        {
          sourceLabels = ["__param_target"]
          targetLabel  = "instance"
        },
        {
          targetLabel = "__address__"
          replacement = "snmp-exporter.${var.namespace_name}.svc.cluster.local:9116"
        }
        ], [for target, device_name in var.scrape_target_to_device_name_map :
        {
          action       = "replace"
          regex        = target
          replacement  = device_name
          sourceLabels = ["__param_target"]
          targetLabel  = "device"
        }
      ])
    }
  }

  depends_on = [kubernetes_service_v1.snmp_exporter]
}
