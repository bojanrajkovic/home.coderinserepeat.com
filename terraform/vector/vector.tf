resource "kubernetes_namespace_v1" "vector" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_config_map_v1" "vector_config" {
  depends_on = [kubernetes_namespace_v1.vector]

  metadata {
    name      = "vector-config"
    namespace = var.namespace_name
  }

  data = {
    "vector.toml" = <<-EOT
      [sources.syslog_tcp]
      type = "syslog"
      address = "0.0.0.0:514"
      mode = "tcp"

      [sources.syslog_udp]
      type = "syslog"
      address = "0.0.0.0:514"
      mode = "udp"

      [transforms.add_metadata]
      type = "remap"
      inputs = ["syslog_tcp", "syslog_udp"]
      source = '''
        .source_type = "syslog"
        .cluster = "homelab"
      '''

      [transforms.to_json]
      type = "remap"
      inputs = ["add_metadata"]
      source = '''
        ., err = {
          "timestamp": to_string(.timestamp),
          "message": .message,
          "hostname": .hostname,
          "appname": .appname,
          "facility": .facility,
          "severity": .severity,
          "source_type": .source_type,
          "cluster": .cluster
        }
      '''

      [sinks.loki]
      type = "loki"
      inputs = ["to_json"]
      endpoint = "${var.loki_endpoint}"
      encoding.codec = "json"

      [sinks.loki.labels]
      job = "vector-syslog"
      hostname = "{{ hostname }}"
      appname = "{{ appname }}"

      [api]
      enabled = true
      address = "0.0.0.0:8686"
    EOT
  }
}

resource "kubernetes_deployment_v1" "vector" {
  depends_on = [kubernetes_config_map_v1.vector_config]

  metadata {
    name      = "vector"
    namespace = var.namespace_name

    labels = {
      "app.kubernetes.io/name" = "vector"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "vector"
      }
    }

    template {
      metadata {
        name      = "vector"
        namespace = var.namespace_name

        labels = {
          "app.kubernetes.io/name" = "vector"
        }
      }

      spec {
        container {
          image = "timberio/vector:0.50.0-debian@sha256:8e81f992197125f736e1fe5d73117ca6b69a0bb69cf3633f82b9233c9769c9c1"
          name  = "vector"

          args = [
            "--config",
            "/etc/vector/vector.toml"
          ]

          env {
            name  = "VECTOR_LOG"
            value = "debug"
          }

          port {
            name           = "syslog-tcp"
            container_port = 514
            protocol       = "TCP"
          }

          port {
            name           = "syslog-udp"
            container_port = 514
            protocol       = "UDP"
          }

          port {
            name           = "api"
            container_port = 8686
            protocol       = "TCP"
          }

          volume_mount {
            mount_path = "/etc/vector"
            name       = "config"
            read_only  = true
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8686
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8686
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map_v1.vector_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "vector" {
  depends_on = [kubernetes_deployment_v1.vector]

  metadata {
    name      = "vector-syslog"
    namespace = var.namespace_name

    annotations = {
      "external-dns.alpha.kubernetes.io/hostname" = var.vector_hostname
      "metallb.io/ip-allocated-from-pool"         = "metallb-address-pool"
    }

    labels = {
      "app.kubernetes.io/name" = "vector"
    }
  }

  spec {
    type                    = "LoadBalancer"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      name        = "syslog-tcp"
      port        = 514
      target_port = "syslog-tcp"
      protocol    = "TCP"
    }

    port {
      name        = "syslog-udp"
      port        = 514
      target_port = "syslog-udp"
      protocol    = "UDP"
    }

    selector = {
      "app.kubernetes.io/name" = "vector"
    }
  }
}
