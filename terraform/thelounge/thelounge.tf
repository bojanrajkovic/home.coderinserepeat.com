resource "kubernetes_namespace_v1" "the_lounge" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "lounge_data" {
  depends_on = [kubernetes_namespace_v1.the_lounge]

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

resource "kubernetes_deployment_v1" "the_lounge" {
  depends_on = [kubernetes_persistent_volume_claim_v1.lounge_data]

  metadata {
    name      = "the-lounge"
    namespace = var.namespace_name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "the_lounge"
      }
    }

    template {
      metadata {
        name      = "the-lounge"
        namespace = var.namespace_name

        labels = {
          "app.kubernetes.io/name" = "the_lounge"
        }
      }

      spec {
        container {
          image = "ghcr.io/thelounge/thelounge:4.4.3@sha256:8e0a075f7461aaa566cf552eef1d1586b29be9ca1e377ef61cb77461b2d16c6c"
          name  = "the-lounge"

          port {
            name           = "web"
            container_port = 9000
            protocol       = "TCP"
          }

          volume_mount {
            mount_path = "/var/opt/thelounge"
            name       = var.data_volume_name
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

resource "kubernetes_service_v1" "the_lounge" {
  depends_on = [kubernetes_namespace_v1.the_lounge]

  metadata {
    name      = "lounge-srv"
    namespace = var.namespace_name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      name        = "web"
      port        = 80
      protocol    = "TCP"
      target_port = "web"
    }

    selector = {
      "app.kubernetes.io/name" = "the_lounge"
    }
  }
}

resource "kubernetes_ingress_v1" "the_lounge" {
  depends_on = [kubernetes_service_v1.the_lounge]

  metadata {
    name      = "lounge"
    namespace = var.namespace_name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.lounge_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "lounge-srv"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.lounge_host]
      secret_name = "lounge-ingress-cert"
    }
  }
}
