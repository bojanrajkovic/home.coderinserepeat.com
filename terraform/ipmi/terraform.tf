locals {
  module = basename(abspath(path.module))
}

terraform {
  required_version = ">= 1.8, < 2.0"

  backend "s3" {
    bucket = "rajkovic-homelab-tf-state"
    key    = "k8s/${local.module}.tfstate"
    region = "us-east-1"
  }

  required_providers {
    system = {
      source  = "neuspaces/system"
      version = "~> 0"
    }
  }
}

provider "system" {
  ssh {
    host  = var.system_host
    port  = 22
    user  = var.system_username
    agent = true
  }
  sudo = true
}
