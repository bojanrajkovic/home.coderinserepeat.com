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
