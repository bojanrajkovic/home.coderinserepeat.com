locals {
  persistence_config = tomap({
    "grafana.persistence.enabled"                                                               = "true"
    "grafana.persistence.type"                                                                  = "pvc"
    "grafana.persistence.storageClassName"                                                      = "zfs-durable"
    "grafana.persistence.size"                                                                  = "1Gi"
    "prometheus.prometheusSpec.retentionSize"                                                   = "30GiB"
    "prometheus.prometheusSpec.retention"                                                       = "1y"
    "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"           = "zfs-durable"
    "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"             = "ReadWriteOnce"
    "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage" = "100Gi"
  })
}

resource "helm_release" "kube_prometheus" {
  name             = "kube-prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "kube-prometheus"
  create_namespace = true
  version          = "75.5.0"

  dynamic "set" {
    for_each = toset([
      "defaultRules.disabled.KubeControllerManagerDown",
      "defaultRules.disabled.KubeProxyDown",
      "defaultRules.disabled.PrometheusNotConnectedToAlertmanagers",
      "defaultRules.disabled.KubeSchedulerDown"
    ])
    iterator = item

    content {
      name  = item.value
      value = true
    }
  }

  set_list {
    name  = "grafana.persistence.accessModes"
    value = ["ReadWriteOnce"]
  }

  set_list {
    name  = "grafana.persistence.finalizers"
    value = ["kubernetes.io/pvc-protection"]
  }

  dynamic "set" {
    for_each = local.persistence_config
    iterator = item

    content {
      name  = item.key
      value = item.value
    }
  }

  dynamic "set" {
    for_each = toset([
      "defaultRules.rules.alertmanager",
      "defaultRules.rules.etcd",
      "kubeControllerManager.enabled",
      "kubeProxy.enabled",
      "kubeScheduler.enabled",
      "alertmanager.enabled",
      "grafana.defaultDashboardsEnabled",
      "grafana.sidecar.dashboards.enabled",
      "grafana.sidecar.datasources.enabled"
    ])
    iterator = item

    content {
      name  = item.value
      value = false
    }
  }
}
