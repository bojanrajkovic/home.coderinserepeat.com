locals {
  module = basename(abspath(path.module))
}

terraform {
  backend "s3" {
    bucket = "rajkovic-homelab-tf-state"
    key    = "k8s/${local.module}.tfstate"
    region = "us-east-1"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3"
    }
  }
}

provider "kubernetes" {}
