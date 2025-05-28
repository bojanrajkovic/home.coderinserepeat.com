locals {
  values = tomap({
    "deploymentMode"                                               = "SingleBinary"
    "loki.auth_enabled"                                            = false
    "loki.commonConfig.replication_factor"                         = 1
    "loki.storage.type"                                            = "filesystem"
    "loki.schemaConfig.configs[0].from"                            = "2024-01-01"
    "loki.schemaConfig.configs[0].store"                           = "tsdb"
    "loki.schemaConfig.configs[0].index.prefix"                    = "loki_index_"
    "loki.schemaConfig.configs[0].index.period"                    = "24h"
    "loki.schemaConfig.configs[0].object_store"                    = "filesystem"
    "loki.schemaConfig.configs[0].schema"                          = "v13"
    "singleBinary.replicas"                                        = 1
    "read.replicas"                                                = 0
    "write.replicas"                                               = 0
    "backend.replicas"                                             = 0
    "singleBinary.persistence.storageClass"                        = "zfs-durable"
    "singleBinary.persistence.size"                                = "50Gi"
    "gateway.ingress.enabled"                                      = true
    "gateway.ingress.ingressClassName"                             = "traefik"
    "gateway.ingress.hosts[0].host"                                = var.loki_hostname
    "gateway.ingress.hosts[0].paths[0].path"                       = "/"
    "gateway.ingress.hosts[0].paths[0].pathType"                   = "Prefix"
    "gateway.ingress.tls[0].hosts[0]"                              = var.loki_hostname
    "gateway.ingress.tls[0].secretName"                            = "loki-cert"
    "gateway.ingress.annotations.cert-manager\\.io/cluster-issuer" = "letsencrypt"
    "monitoring.dashboards.enabled"                                = false
    "monitoring.rules.enabled"                                     = false
    "monitoring.serviceMonitor.enabled"                            = true
    "monitoring.serviceMonitor.labels.release"                     = "kube-prometheus"
  })
}

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  namespace        = var.namespace_name
  create_namespace = true
  version          = "6.30.1"

  dynamic "set" {
    for_each = local.values
    iterator = value

    content {
      name  = value.key
      value = value.value
    }
  }
}
