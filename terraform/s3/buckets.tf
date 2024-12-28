resource "aws_s3_bucket" "bucket" {
  for_each = var.bucket_list
  bucket   = each.value
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  for_each = var.bucket_list
  bucket   = aws_s3_bucket.bucket[each.value].id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = each.value != "coderinserepeat.com" ? "aws:kms" : "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups_bucket_lifecycle_configuration" {
  bucket = "bojans-backups"

  rule {
    id     = "MoveToStandardIAAfter30Days"
    status = "Enabled"

    transition {
      storage_class = "STANDARD_IA"
      days          = 30
    }

    transition {
      storage_class = "GLACIER_IR"
      days          = 90
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
