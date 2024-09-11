resource "kubernetes_namespace" "ustreamer" {
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

resource "kubernetes_deployment_v1" "ustreamer" {
  depends_on = [kubernetes_namespace.ustreamer]

  metadata {
    name      = "ustreamer"
    namespace = kubernetes_namespace.ustreamer.metadata[0].name
  }


  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "ustreamer"
      }
    }

    template {
      metadata {
        name      = "ustreamer"
        namespace = kubernetes_namespace.ustreamer.metadata[0].name

        labels = {
          "app.kubernetes.io/name" = "ustreamer"
        }
      }

      spec {
        os {
          name = "linux"
        }

        node_name = "hagal"

        container {
          image = "mkuf/ustreamer:v6.16@sha256:56505ddfce9f265d51b0ed4aaef531c08830c3952515eba55aa0c93ce7a16ae6"
          name  = "ustreamer"

          args = [
            "--format=mjpeg",
            "--encoder=hw",
            "--workers=4",
            "--persistent",
            "--resolution=3840x2160",
            "--host=0.0.0.0",
            "--port=8080"
          ]

          port {
            container_port = 8080
            protocol       = "TCP"
          }

          resources {
            requests = {
              for capacity
              in keys(data.kubernetes_nodes.hagal.nodes[0].status[0].capacity) :
              capacity => 1
              if length(regexall("smarter-devices/video.*", capacity)) > 0
            }
            limits = {
              for capacity
              in keys(data.kubernetes_nodes.hagal.nodes[0].status[0].capacity) :
              capacity => 1
              if length(regexall("smarter-devices/video.*", capacity)) > 0
            }
          }

          security_context {
            capabilities {
              add = ["SYS_RAWIO"]
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "ustreamer" {
  metadata {
    name      = "ustreamer"
    namespace = kubernetes_namespace.ustreamer.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 8080
      protocol    = "TCP"
      target_port = "8080"
    }

    selector = {
      "app.kubernetes.io/name" = "ustreamer"
    }
  }
}

resource "kubernetes_ingress_v1" "ustreamer" {
  depends_on = [kubernetes_namespace.ustreamer, kubernetes_service_v1.ustreamer]

  metadata {
    name      = "ustreamer"
    namespace = kubernetes_namespace.ustreamer.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.ustreamer_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "ustreamer"

              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.ustreamer_host]
      secret_name = "ustreamer-ingress-cert"
    }
  }
}
