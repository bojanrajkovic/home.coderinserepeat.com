resource "helm_release" "cloudnative_pg" {
  name             = "cloudnative-pg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  set {
    name  = "monitoring.podMonitorEnabled"
    value = true
  }
}
