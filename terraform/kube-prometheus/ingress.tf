resource "kubernetes_ingress_v1" "grafana_ingress" {
  metadata {
    name      = "grafana-ingress"
    namespace = var.namespace_name
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.grafana_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "kube-prometheus-grafana"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.grafana_host]
      secret_name = "grafana-ingress-cert"
    }
  }
}
