terraform {
  backend "s3" {
    bucket = "rajkovic-homelab-tf-state"
    key    = "aws/${basename(abspath(path.module))}.tfstate"
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
      "module"         = basename(abspath(path.module))
    }
  }
  region = "us-east-1"
}
