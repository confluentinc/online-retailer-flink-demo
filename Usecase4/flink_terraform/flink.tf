
# Here we are using the Confluent provider for managing Confluent Cloud resources.
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.5.0"                  
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key    # optionally use CONFLUENT_CLOUD_API_KEY env var
  cloud_api_secret = var.confluent_cloud_api_secret # optionally use CONFLUENT_CLOUD_API_SECRET env var
}

# Data sources

data "confluent_organization" "demo_org" {}

data "confluent_environment" "demo_environment" {
  id = var.confluent_cloud_environment_id
}

data "confluent_kafka_cluster" "demo_cluser" {
  id = var.confluent_cloud_cluster_id
  environment {
    id = data.confluent_environment.demo_environment.id
  }
}

data "confluent_flink_region" "demo_flink_region" {
  cloud   = "AWS"
  region  = var.cloud_region
}

# Flink statement

resource "confluent_flink_statement" "CTAS" {
  organization {
    id = data.confluent_organization.demo_org.id
  }
  environment {
    id = data.confluent_environment.demo_environment.id
  }
  compute_pool {
    id = var.demo_compute_pool_id
  }
  principal {
    id = var.confluent_cloud_service_account_id
  }
  statement  = <<-EOT
  CREATE TABLE terraform_revenue_summary
  AS SELECT *
  FROM revenue_summary;
  
  EOT
  properties = {
    "sql.current-catalog"  = data.confluent_environment.demo_environment.display_name
    "sql.current-database" = data.confluent_kafka_cluster.demo_cluser.display_name
  }
  # Use data.confluent_flink_region.main.rest_endpoint for Basic, Standard, public Dedicated Kafka clusters
  # and data.confluent_flink_region.main.private_rest_endpoint for Kafka clusters with private networking
  rest_endpoint = data.confluent_flink_region.demo_flink_region.rest_endpoint
  credentials {
    key    = var.flink_management_api_key
    secret = var.flink_management_api_key_secret
  }
  stopped = var.flink_statement_stopped

}