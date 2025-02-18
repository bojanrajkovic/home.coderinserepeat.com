resource "helm_release" "zfs-localpv" {
  name             = "zfs-localpv"
  repository       = "https://openebs.github.io/zfs-localpv"
  chart            = "zfs-localpv"
  namespace        = "openebs"
  create_namespace = true
  version          = "2.7.1"
}

resource "kubernetes_storage_class_v1" "zfs-durable" {
  metadata {
    name = "zfs-durable"
  }

  parameters = {
    recordsize  = "128k"
    compression = "on"
    dedup       = "off"
    fstype      = "zfs"
    poolname    = var.durable_storage_pool_name
  }

  storage_provisioner = "zfs.csi.openebs.io"
}

resource "kubernetes_storage_class_v1" "zfs-scratch" {
  metadata {
    name = "zfs-scratch"
  }

  parameters = {
    recordsize  = "128k"
    compression = "on"
    dedup       = "off"
    fstype      = "zfs"
    poolname    = var.scratch_storage_pool_name
  }

  storage_provisioner = "zfs.csi.openebs.io"
}
