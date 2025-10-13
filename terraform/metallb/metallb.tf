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
