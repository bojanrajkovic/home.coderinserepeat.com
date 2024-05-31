locals {
  manifest_groups = ["./manifests/metallb-native.yaml", "./manifests/metallb-bgp.yaml", "./manifests/metallb-monitoring.yaml"]
  manifests = {
    for manifest in flatten([
      for manifest_group in local.manifest_groups : provider::kubernetes::manifest_decode_multi(file("./${manifest_group}"))
    ]) : "${manifest.kind}--${manifest.metadata.name}" => manifest
  }
}

resource "kubernetes_manifest" "metallb" {
  for_each = local.manifests

  field_manager {
    force_conflicts = true
  }

  manifest = each.value
}

import {
  for_each = local.manifests
  to       = kubernetes_manifest.metallb[each.key]
  id       = "apiVersion=${each.value.apiVersion},kind=${each.value.kind},%{if can(each.value.metadata.namespace)}namespace=${each.value.metadata.namespace},%{endif}name=${each.value.metadata.name}"
}
