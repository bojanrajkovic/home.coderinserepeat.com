locals {
  management_ports = [29811, 29812, 29813, 29814, 29815, 29816]
}

resource "kubernetes_namespace_v1" "omada" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "omada_data" {
  depends_on = [kubernetes_namespace_v1.omada]

  metadata {
    name      = var.data_volume_name
    namespace = var.namespace_name
  }

  spec {
    storage_class_name = var.data_volume_storage_class
    access_modes       = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.data_volume_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "omada_logs" {
  depends_on = [kubernetes_namespace_v1.omada]

  metadata {
    name      = var.logs_volume_name
    namespace = var.namespace_name
  }

  spec {
    storage_class_name = var.logs_volume_storage_class
    access_modes       = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.logs_volume_size
      }
    }
  }
}

resource "kubernetes_deployment_v1" "omada" {
  depends_on = [
    kubernetes_persistent_volume_claim_v1.omada_data,
    kubernetes_persistent_volume_claim_v1.omada_logs,
    kubernetes_namespace_v1.omada
  ]

  metadata {
    name      = "omada-controller"
    namespace = var.namespace_name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }


    selector {
      match_labels = {
        "app.kubernetes.io/name" = "omada-controller"
      }
    }

    template {
      metadata {
        name      = "omada-controller"
        namespace = var.namespace_name

        labels = {
          "app.kubernetes.io/name" = "omada-controller"
        }
      }

      spec {
        host_network = true
        dns_policy   = "ClusterFirstWithHostNet"

        container {
          image = "mbentley/omada-controller:5.15-chromium@sha256:449d103e5ed4a62f05a283797cfa1130530460e02ad3f61c07235bc017981095"
          name  = "omada-controller"

          env {
            name  = "SHOW_SERVER_LOGS"
            value = true
          }

          env {
            name  = "SHOW_MONGODB_LOGS"
            value = true
          }

          env {
            name  = "TZ"
            value = "America/New_York"
          }

          port {
            name           = "websecure"
            container_port = 8043
            protocol       = "TCP"
          }

          port {
            name           = "initialization"
            container_port = 27001
            protocol       = "UDP"
          }

          dynamic "port" {
            for_each = local.management_ports

            content {
              name           = "mgmt-${port.value}"
              container_port = port.value
              protocol       = "TCP"
            }
          }

          port {
            name           = "discovery"
            container_port = 29810
            protocol       = "UDP"
          }

          volume_mount {
            mount_path = "/opt/tplink/EAPController/data"
            name       = var.data_volume_name
          }

          volume_mount {
            mount_path = "/opt/tplink/EAPController/logs"
            name       = var.logs_volume_name
          }
        }

        volume {
          name = var.data_volume_name

          persistent_volume_claim {
            claim_name = var.data_volume_name
          }
        }

        volume {
          name = var.logs_volume_name

          persistent_volume_claim {
            claim_name = var.logs_volume_name
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "omada_skip_verify" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "ServersTransport"

    metadata = {
      "name"      = "omada-skipverify"
      "namespace" = var.namespace_name
    }

    spec = {
      insecureSkipVerify = true
    }
  }
}

resource "kubernetes_service_v1" "omada" {
  depends_on = [kubernetes_namespace_v1.omada, kubernetes_manifest.omada_skip_verify]

  metadata {
    name      = "omada-srv"
    namespace = var.namespace_name

    annotations = {
      "traefik.ingress.kubernetes.io/service.serversscheme"    = "https"
      "traefik.ingress.kubernetes.io/service.serverstransport" = "omada-omada-skipverify@kubernetescrd"
    }
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      name        = "websecure"
      port        = 8043
      protocol    = "TCP"
      target_port = "websecure"
    }

    selector = {
      "app.kubernetes.io/name" = "omada-controller"
    }
  }
}

resource "kubernetes_ingress_v1" "omada" {
  depends_on = [kubernetes_service_v1.omada]

  metadata {
    name      = "omada"
    namespace = var.namespace_name

    annotations = {
      "cert-manager.io/cluster-issuer"           = "letsencrypt"
      "kubernetes.io/ingress.class"              = "traefik"
      "traefik.ingress.kubernetes.io/router.tls" = true
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.omada_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "omada-srv"

              port {
                number = 8043
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.omada_host]
      secret_name = "omada-ingress-cert"
    }
  }
}
