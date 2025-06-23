resource "helm_release" "password_operator" {
  name       = "1password-operator"
  repository = "https://1password.github.io/connect-helm-charts/"
  chart      = "connect"
  version    = "1.17.1"

  set {
    name  = "connect.credentials"
    value = " ${replace(file("../../secrets/1password/1password-credentials.json"), ",", "\\,")}"
  }

  set {
    name  = "operator.create"
    value = "true"
  }

  set {
    name  = "operator.token.value"
    value = file("../../secrets/1password/connect-token.txt")
  }

  set {
    name  = "operator.autoRestart"
    value = "true"
  }
}
