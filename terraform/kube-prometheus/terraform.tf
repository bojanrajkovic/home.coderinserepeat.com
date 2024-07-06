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

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 3"
    }
  }
}

provider "grafana" {
  url  = "https://${var.grafana_host}"
  auth = var.grafana_auth_key
}

provider "kubernetes" {}

provider "helm" {}
