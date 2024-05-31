resource "kubernetes_namespace" "octoprint" {
  metadata {
    name = var.namespace_name
    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

data "kubernetes_nodes" "hagal" {
  metadata {
    labels = {
      "kubernetes.io/hostname" = "hagal"
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "octoprint" {
  depends_on = [kubernetes_namespace.octoprint]
  metadata {
    name      = var.data_volume_name
    namespace = var.namespace_name
  }
  spec {
    storage_class_name = var.data_volume_storage_class
    access_modes       = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.data_volume_size
      }
    }
  }
}

resource "kubernetes_deployment_v1" "octoprint" {
  depends_on = [kubernetes_namespace.octoprint, data.kubernetes_nodes.hagal, kubernetes_persistent_volume_claim_v1.octoprint]

  metadata {
    name      = "octoprint"
    namespace = kubernetes_namespace.octoprint.metadata[0].name
  }


  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "octoprint"
      }
    }
    template {
      metadata {
        name      = "octoprint"
        namespace = kubernetes_namespace.octoprint.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "octoprint"
        }
      }
      spec {
        os {
          name = "linux"
        }

        node_name = "hagal"

        container {
          image = "docker.io/octoprint/octoprint"
          name  = "octoprint"

          env {
            name  = "OCTOPRINT_PORT"
            value = 80
          }

          port {
            container_port = 80
            protocol       = "TCP"
          }

          volume_mount {
            mount_path = "/${var.data_volume_name}"
            name       = var.data_volume_name
          }

          resources {
            requests = {
              for capacity
              in keys(data.kubernetes_nodes.hagal.nodes[0].status[0].capacity) :
              capacity => 1
              if length(regexall("smarter-devices/(video|tty).*", capacity)) > 0
            }
            limits = {
              for capacity
              in keys(data.kubernetes_nodes.hagal.nodes[0].status[0].capacity) :
              capacity => 1
              if length(regexall("smarter-devices/(video|tty).*", capacity)) > 0
            }
          }

          security_context {
            capabilities {
              add = ["SYS_RAWIO"]
            }
          }
        }

        volume {
          name = var.data_volume_name
          persistent_volume_claim {
            claim_name = var.data_volume_name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "octoprint" {
  metadata {
    name      = "octoprint"
    namespace = kubernetes_namespace.octoprint.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 80
      protocol    = "TCP"
      target_port = "80"
    }

    selector = {
      "app.kubernetes.io/name" : "octoprint"
    }
  }
}

resource "kubernetes_ingress_v1" "octoprint" {
  depends_on = [kubernetes_namespace.octoprint, kubernetes_service_v1.octoprint]

  metadata {
    name      = "octoprint"
    namespace = kubernetes_namespace.octoprint.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"
    rule {
      host = var.octoprint_host
      http {
        path {
          path = "/"
          backend {
            service {
              name = "octoprint"
              port {
                number = 80
              }
            }
          }
          path_type = "Prefix"
        }
      }
    }

    tls {
      hosts = [
        var.octoprint_host,
      ]
      secret_name = "octoprint-ingress-cert"
    }
  }
}
