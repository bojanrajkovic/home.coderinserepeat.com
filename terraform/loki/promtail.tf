locals {
  promtail_manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(file("./manifests/promtail-cluster-daemonset.yaml"))
    : "${manifest.kind}--${manifest.metadata.name}" => manifest
  }
}

resource "kubernetes_manifest" "promtail" {
  for_each = local.promtail_manifests

  field_manager {
    force_conflicts = true
  }

  manifest = each.value
}

import {
  for_each = local.promtail_manifests
  to       = kubernetes_manifest.promtail[each.key]
  id       = "apiVersion=${each.value.apiVersion},kind=${each.value.kind},%{if can(each.value.metadata.namespace)}namespace=${each.value.metadata.namespace},%{endif}name=${each.value.metadata.name}"
}
