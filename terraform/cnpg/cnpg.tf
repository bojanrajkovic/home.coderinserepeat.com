resource "helm_release" "cloudnative_pg" {
  name             = "cloudnative-pg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  namespace        = var.namespace
  create_namespace = true
  version          = "v0.21.4"

  set {
    name  = "monitoring.podMonitorEnabled"
    value = true
  }
}
