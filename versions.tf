
terraform {
  required_version = ">= 0.13"
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
  }
}
