output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.staging.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.standard.id}

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
  ${confluent_service_account.app-manager.display_name}:                     ${confluent_service_account.app-manager.id}
  ${confluent_service_account.app-manager.display_name}'s Kafka API Key:     "${confluent_api_key.app-manager-kafka-api-key.id}"
  ${confluent_service_account.app-manager.display_name}'s Kafka API Secret:  "${confluent_api_key.app-manager-kafka-api-key.secret}"

  sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="${confluent_api_key.app-manager-kafka-api-key.id}" password="${confluent_api_key.app-manager-kafka-api-key.secret}";
  bootstrap.servers=${confluent_kafka_cluster.standard.bootstrap_endpoint}
  schema.registry.url= ${data.confluent_schema_registry_cluster.sr-cluster.rest_endpoint}
  schema.registry.basic.auth.user.info= "${confluent_api_key.app-manager-schema-registry-api-key.id}:${confluent_api_key.app-manager-schema-registry-api-key.secret}"

  RDS Endpoint: ${aws_db_instance.postgres_db.endpoint}
  KMS Key ARN: ${aws_kms_key.kms_key.arn}

  PrivateKey: ${local.private_key_no_headers}
  PublicKey: ${local.public_key_no_headers}

  Snowflake Connection URL: https://${var.snowflake_account}.snowflakecomputing.com

  EOT

  sensitive = true
}
