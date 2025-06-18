resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = var.namespace
  create_namespace = true
  version          = "v1.18.1"

  set {
    name  = "crds.enabled"
    value = true
  }
}
