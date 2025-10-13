resource "kubernetes_namespace_v1" "emqx" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_manifest" "emqx_tls_certificate" {
  depends_on = [kubernetes_namespace_v1.emqx]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "emqx-listeners-tls"
      namespace = var.namespace_name
    }

    spec = {
      secretName = "emqx-listeners-tls"

      issuerRef = {
        name  = "letsencrypt"
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }

      dnsNames = [
        var.emqx_hostname
      ]

      duration    = "2160h" # 90 days
      renewBefore = "360h"  # 15 days before expiry

      usages = [
        "server auth",
        "client auth"
      ]
    }
  }
}

resource "kubernetes_manifest" "emqx_cluster" {
  depends_on = [
    helm_release.emqx_operator,
    kubernetes_namespace_v1.emqx,
    kubernetes_manifest.emqx_tls_certificate
  ]

  manifest = {
    apiVersion = "apps.emqx.io/v2beta1"
    kind       = "EMQX"

    metadata = {
      name      = "emqx"
      namespace = var.namespace_name
    }

    spec = {
      image = "emqx/emqx:5.8.5"

      config = {
        data = <<-EOT
          listeners.ssl.default {
            bind = "0.0.0.0:8883"
            ssl_options {
              cacertfile = "/mounted/cert/ca.crt"
              certfile = "/mounted/cert/tls.crt"
              keyfile = "/mounted/cert/tls.key"
            }
          }
          listeners.wss.default {
            bind = "0.0.0.0:8084"
            ssl_options {
              cacertfile = "/mounted/cert/ca.crt"
              certfile = "/mounted/cert/tls.crt"
              keyfile = "/mounted/cert/tls.key"
            }
          }
        EOT
      }

      coreTemplate = {
        spec = {
          extraVolumes = [
            {
              name = "emqx-tls"
              secret = {
                secretName = "emqx-listeners-tls"
              }
            }
          ]

          extraVolumeMounts = [
            {
              name      = "emqx-tls"
              mountPath = "/mounted/cert"
              readOnly  = true
            }
          ]
        }
      }

      dashboardServiceTemplate = {
        spec = {
          type = "ClusterIP"
        }
      }

      listenersServiceTemplate = {
        metadata = {
          annotations = {
            "metallb.io/ip-allocated-from-pool"         = "metallb-address-pool"
            "external-dns.alpha.kubernetes.io/hostname" = var.emqx_hostname
          }
        }

        spec = {
          type = "LoadBalancer"
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "emqx_dashboard" {
  depends_on = [kubernetes_manifest.emqx_cluster]

  metadata {
    name      = "emqx-dashboard"
    namespace = var.namespace_name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.emqx_dashboard_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "emqx-dashboard"

              port {
                number = 18083
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.emqx_dashboard_hostname]
      secret_name = "emqx-dashboard-ingress-cert"
    }
  }
}
