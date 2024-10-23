# AWS provider configuration
# This is required to manage AWS resources. The region is dynamically set via a variable.
provider "aws" {
  region = var.cloud_region  
  # Default tags to apply to all resources
  default_tags {
    tags = {
      Created_by = "Shift-left Terraform script"
      Project     = "Shift-left Demo"
      owner_email       = var.email
    }
  }
}

# Here we are using the Confluent provider for managing Confluent Cloud resources.
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.5.0"                  
    }
    snowflake = {
      source = "Snowflake-Labs/snowflake"
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

# TLS provider for generating RSA key-pairs used by Snowflake Connector and certificates.
provider "tls" {}

# Snowflake provider for managing Snowflake resources.
provider "snowflake" {
  account  = var.snowflake_account
  user = var.snowflake_username
  password = var.snowflake_password
}
