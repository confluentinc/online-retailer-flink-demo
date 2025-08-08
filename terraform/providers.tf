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
      version = "0.98.0"  
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


module "redshift" {
  source = "./modules/redshift"
  count  = var.data_warehouse == "redshift" ? 1 : 0  # Only deploy module if Redshift is selected
  
  prefix     = var.prefix
  random_id  = random_id.env_display_id.hex
  subnet_id  = aws_subnet.public_subnet.id
  vpc_id     = aws_vpc.ecs_vpc.id
}

/*
# UNCOMMENT THE FOLLOWING 2 CONFIG BLOCKS, IF YOU WANT TO DEPLOY THE DEMO WITH SNOWFLAKE

# Snowflake provider configuration

provider "snowflake" {
  alias = "snowflake"
  account  = var.data_warehouse == "snowflake" ? var.snowflake_account : "na"
  user     = var.data_warehouse == "snowflake" ? var.snowflake_username : "na"
  password = var.data_warehouse == "snowflake" ? var.snowflake_password : "na"
}


module "snowflake" {
  source = "./modules/snowflake"
  count  = var.data_warehouse == "snowflake" ? 1 : 0  # Only deploy module if Snowflake is selected
  providers = {
    snowflake = snowflake.snowflake
  }
  # Pass the variables required for Snowflake resources
  snowflake_account  = var.snowflake_account
  snowflake_username = var.snowflake_username
  snowflake_password = var.snowflake_password
  public_key_no_headers = local.public_key_no_headers
}
*/

resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
}

# Define local variables to strip PEM headers and footers
locals {
  # Remove the PEM headers and footers for the private key
  private_key_no_headers = replace(replace(tls_private_key.rsa_key.private_key_pem, "-----BEGIN RSA PRIVATE KEY-----", ""), "-----END RSA PRIVATE KEY-----", "")
  
  # Remove the PEM headers and footers for the public key
  public_key_no_headers = replace(replace(tls_private_key.rsa_key.public_key_pem, "-----BEGIN PUBLIC KEY-----", ""), "-----END PUBLIC KEY-----", "")
}



