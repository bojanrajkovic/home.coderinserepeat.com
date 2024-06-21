terraform {
  backend "s3" {
    bucket = "rajkovic-homelab-tf-state"
    key    = "k8s/backrest.tfstate"
    region = "us-east-1"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }

    system = {
      source  = "neuspaces/system"
      version = "~> 0"
    }

    healthchecksio = {
      version = "~> 2"
      source  = "kristofferahl/healthchecksio"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      "provisioned-by" = "terraform"
      "module"         = "${basename(path.cwd)}"
    }
  }
  region = "us-east-1"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
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

provider "healthchecksio" {
  api_key = var.healthchecksio_api_key
  api_url = var.healthchecksio_host
}
