variable "durable_storage_pool_name" {
  type        = string
  description = "Pool name to place durable OpenEBS-managed ZFS datasets under"
}

variable "scratch_storage_pool_name" {
  type        = string
  description = "Pool name to place scratch OpenEBS-managed ZFS datasets under"
}
