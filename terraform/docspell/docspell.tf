resource "kubernetes_namespace" "docspell" {
  metadata {
    name = var.namespace

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "docspell_data_volume" {
  metadata {
    name      = var.docspell_data_volume
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.volume_storage_class

    resources {
      requests = {
        storage = var.docspell_data_volume_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "docspell_configuration_volume" {
  metadata {
    name      = var.docspell_configuration_volume
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.volume_storage_class

    resources {
      requests = {
        storage = var.docspell_configuration_volume_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "solr_data_volume" {
  metadata {
    name      = var.solr_data_volume
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.volume_storage_class

    resources {
      requests = {
        storage = var.solr_volume_size
      }
    }
  }
}

resource "kubernetes_deployment_v1" "docspell" {
  depends_on = [kubernetes_namespace.docspell]

  metadata {
    name      = "docspell"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "docspell"
      }
    }

    template {
      metadata {
        name      = "docspell"
        namespace = var.namespace

        labels = {
          "app.kubernetes.io/name" = "docspell"
        }
      }

      spec {
        security_context {
          fs_group               = 2000
          fs_group_change_policy = "OnRootMismatch"
        }

        // Docspell Restserver
        container {
          name  = "restserver"
          image = "docker.io/docspell/restserver:v0.42.0@sha256:7184e723dcdd5241f02372748ad0aab6caca0722478abc892dc63c663e399f2d"
          args  = ["/var/docspell/docspell.conf"]

          port {
            name           = "web-restserver"
            container_port = 7880
            protocol       = "TCP"
          }

          env {
            name  = "TZ"
            value = "America/New_York"
          }

          // Configuration
          volume_mount {
            mount_path = "/var/docspell"
            name       = var.docspell_configuration_volume
          }

          // Data
          volume_mount {
            mount_path = "/var/spool/docspell/docs"
            name       = var.docspell_data_volume
          }
        }

        // Docspell Joex
        container {
          name  = "joex"
          image = "docker.io/docspell/joex:v0.42.0@sha256:b21d2285e49c0869d827dcba631ff10d574c673eb8df2ebf7fc1f326d0afd581"
          args  = ["/var/docspell/docspell.conf"]

          port {
            name           = "web-joex"
            container_port = 7878
            protocol       = "TCP"
          }

          env {
            name  = "TZ"
            value = "America/New_York"
          }

          // Configuration
          volume_mount {
            mount_path = "/var/docspell"
            name       = var.docspell_configuration_volume
          }

          // Data
          volume_mount {
            mount_path = "/var/spool/docspell/docs"
            name       = var.docspell_data_volume
          }
        }

        // Docspell Solr
        container {
          name  = "solr"
          image = "docker.io/solr:9@sha256:4d7fc4c8dd0c274b43ad12b4b6b0ee2f2f350f9669858d49bcfe2518ce74c4ef"
          args  = ["-f", "-Dsolr.modules=analysis-extras"]

          port {
            name           = "web-solr"
            container_port = 8983
            protocol       = "TCP"
          }

          // Configuration + Data
          volume_mount {
            mount_path = "/var/solr"
            name       = var.solr_data_volume
          }
        }

        volume {
          name = var.solr_data_volume

          persistent_volume_claim {
            claim_name = var.solr_data_volume
          }
        }

        volume {
          name = var.docspell_configuration_volume

          persistent_volume_claim {
            claim_name = var.docspell_configuration_volume
          }
        }

        volume {
          name = var.docspell_data_volume

          persistent_volume_claim {
            claim_name = var.docspell_data_volume
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "docspell" {
  metadata {
    name      = "docspell"
    namespace = kubernetes_namespace.docspell.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 80
      target_port = 7880
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "docspell"
    }
  }
}

resource "kubernetes_ingress_v1" "docspell" {
  metadata {
    name      = "docspell"
    namespace = kubernetes_namespace.docspell.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.docspell_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "docspell"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.docspell_host]
      secret_name = "docspell-ingress-cert"
    }
  }
}
