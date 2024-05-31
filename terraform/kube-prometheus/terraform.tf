terraform {
  backend "s3" {
    bucket = "rajkovic-homelab-tf-state"
    key    = "k8s/kube-prometheus.tfstate"
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

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
