# AWS provider configuration
# This is required to manage AWS resources. The region is dynamically set via a variable.
provider "aws" {
  region = var.cloud_region
  # Default tags to apply to all resources
  default_tags {
    tags = {
      Created_by  = "Shift-left Terraform script"
      Project     = "Shift-left Demo"
      owner_email = var.email
    }
  }
}

# Here we are using the Confluent provider for managing Confluent Cloud resources.
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.32.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Local provider for accessing and managing local system resources.
# This is useful for tasks like rendering templates, reading local files, etc.
provider "local" {}

# TLS provider for generating SSH key pairs.
provider "tls" {}

data "aws_ecr_authorization_token" "ecr" {}

provider "docker" {
  registry_auth {
    address  = replace(data.aws_ecr_authorization_token.ecr.proxy_endpoint, "https://", "")
    username = data.aws_ecr_authorization_token.ecr.user_name
    password = data.aws_ecr_authorization_token.ecr.password
  }
}
