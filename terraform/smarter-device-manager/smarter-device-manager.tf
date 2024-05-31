locals {
  smarter_device_manager_manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(file("./manifests/smarter-device-manager.yaml"))
    : "${manifest.kind}--${manifest.metadata.name}" => manifest
  }
}

resource "kubernetes_manifest" "smarter_device_manager" {
  for_each = local.smarter_device_manager_manifests

  field_manager {
    force_conflicts = true
  }

  manifest = each.value
}

import {
  for_each = local.smarter_device_manager_manifests
  to       = kubernetes_manifest.smarter_device_manager[each.key]
  id       = "apiVersion=${each.value.apiVersion},kind=${each.value.kind},%{if can(each.value.metadata.namespace)}namespace=${each.value.metadata.namespace},%{endif}name=${each.value.metadata.name}"
}


resource "kubernetes_labels" "smarter_device_manager_label" {
  api_version = "v1"
  kind        = "Node"

  metadata {
    name = "hagal"
  }

  labels = {
    "smarter-device-manager" = "enabled"
  }
}
