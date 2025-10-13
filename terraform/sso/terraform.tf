locals {
  module = basename(abspath(path.module))
}

terraform {
  required_version = ">= 1.8, < 2.0"

  backend "s3" {
    bucket = "rajkovic-homelab-tf-state"
    key    = "aws/${local.module}.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      "provisioned-by" = "terraform"
      "module"         = local.module
    }
  }
  region = "us-east-1"
}
