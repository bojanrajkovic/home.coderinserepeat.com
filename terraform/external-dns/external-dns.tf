locals {
  external_dns_manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(file("./manifests/external-dns.yaml"))
    : "${manifest.kind}--${manifest.metadata.name}" => manifest
  }
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = var.namespace
    annotations = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_secret" "external_dns_aws_credentials" {
  depends_on = [aws_iam_access_key.external_dns_access_keys, kubernetes_namespace.external_dns]
  metadata {
    name      = "prod-route53-credentials"
    namespace = var.namespace
  }
  data = {
    "secret-access-key" = aws_iam_access_key.external_dns_access_keys.secret
    "access-key-id"     = aws_iam_access_key.external_dns_access_keys.id
  }
}

resource "kubernetes_manifest" "external_dns" {
  depends_on = [kubernetes_secret.external_dns_aws_credentials]
  for_each   = local.external_dns_manifests

  field_manager {
    force_conflicts = true
  }

  manifest = each.value
}

import {
  for_each = local.external_dns_manifests
  to       = kubernetes_manifest.external_dns[each.key]
  id       = "apiVersion=${each.value.apiVersion},kind=${each.value.kind},%{if can(each.value.metadata.namespace)}namespace=${each.value.metadata.namespace},%{endif}name=${each.value.metadata.name}"
}
