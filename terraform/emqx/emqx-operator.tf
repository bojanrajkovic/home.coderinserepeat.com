resource "helm_release" "emqx_operator" {
  name             = "emqx-operator"
  repository       = "https://repos.emqx.io/charts"
  chart            = "emqx-operator"
  namespace        = "emqx-operator-system"
  create_namespace = true
  version          = "2.2.29"
}
