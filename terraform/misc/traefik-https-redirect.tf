resource "kubernetes_manifest" "traefik_https_redirect_config" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChartConfig"

    metadata = {
      name      = "traefik"
      namespace = "kube-system"
    }

    spec = {
      valuesContent = yamlencode({
        ports = {
          websecure = {
            tls = {
              enabled = true
            }
          }
          web = {
            redirections = {
              entrypoint = {
                to        = "websecure"
                scheme    = "https"
                permanent = true
              }
            }
          }
        }
      })
    }
  }

  field_manager {
    force_conflicts = true
  }
}
