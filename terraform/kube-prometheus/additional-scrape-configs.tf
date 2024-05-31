resource "kubernetes_secret_v1" "homeassistant_scrape_key" {
  metadata {
    name      = "homeassistant-scrape-key"
    namespace = var.namespace_name
  }
  data = {
    "key" = var.homeassistant_scrape_key
  }
}

resource "kubernetes_manifest" "homeassistant_scrape_config" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1alpha1"
    kind       = "ScrapeConfig"
    metadata = {
      name      = "homeassistant-scrape-config"
      namespace = var.namespace_name
      labels = {
        release = "kube-prometheus"
      }
    }
    spec = {
      staticConfigs = [
        {
          targets = var.homeassistant_scrape_targets
        }
      ]
      metricsPath       = "api/prometheus"
      scheme            = "HTTPS"
      enableCompression = true
      authorization = {
        credentials = {
          name = kubernetes_secret_v1.homeassistant_scrape_key.metadata[0].name
          key  = "key"
        }
      }
    }
  }
}
