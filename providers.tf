terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    temporalcloud = {
      source  = "temporalio/temporalcloud"
      version = "~> 0.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "temporalcloud" {
  api_key = var.temporal_api_key
}