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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
  }
}

provider "kubernetes" {}

provider "aws" {
  default_tags {
    tags = {
      "provisioned-by" = "terraform"
      "module"         = local.module
    }
  }
  region = "us-east-1"
}

provider "helm" {}
