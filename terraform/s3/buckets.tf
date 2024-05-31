resource "aws_s3_bucket" "bucket" {
  for_each = var.bucket_list
  bucket   = each.value
}

data "aws_kms_alias" "aws_managed_s3_key" {
  name = "alias/aws/s3"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  for_each = var.bucket_list
  bucket   = aws_s3_bucket.bucket[each.value].id
  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = data.aws_kms_alias.aws_managed_s3_key.target_key_arn
      sse_algorithm     = "aws:kms"
    }
  }

}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = "rajkovic-homelab-tf-state"

  versioning_configuration {
    status = "Enabled"
  }
}

import {
  for_each = var.bucket_list
  to       = aws_s3_bucket.bucket[each.value]
  id       = each.value
}
