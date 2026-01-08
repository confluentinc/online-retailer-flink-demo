output "resource-ids" {

  value = <<-EOT

==============================
   ENVIRONMENT & CLUSTER INFO
==============================
  Environment ID:         ${confluent_environment.staging.id}
  Kafka Cluster ID:       ${confluent_kafka_cluster.standard.id}
  Flink Compute Pool ID:  ${confluent_flink_compute_pool.flinkpool-main.id}

------------------------------
   S3 BUCKET
------------------------------
  Name: ${module.aws_s3_bucket.bucket_name}
  ARN:  ${module.aws_s3_bucket.bucket_arn}

------------------------------
   PROVIDER INTEGRATION
------------------------------

  Role ARN:     ${module.provider_integration.provider_integration_role_arn}
  External ID:  ${module.provider_integration.provider_integration_external_id}

------------------------------
   SERVICE ACCOUNTS & API KEYS
------------------------------
  App Manager: ${confluent_service_account.app-manager.display_name}
    - ID:         ${confluent_service_account.app-manager.id}
    - Kafka API Key:    "${confluent_api_key.app-manager-kafka-api-key.id}"
    - Kafka API Secret: "${confluent_api_key.app-manager-kafka-api-key.secret}"
    - Flink API Key:    "${confluent_api_key.app-manager-flink-api-key.id}"
    - Flink API Secret: "${confluent_api_key.app-manager-flink-api-key.secret}"

------------------------------
   CONNECTION CONFIGS
------------------------------
  SASL JAAS Config:
    org.apache.kafka.common.security.plain.PlainLoginModule required \
      username="${confluent_api_key.app-manager-kafka-api-key.id}" \
      password="${confluent_api_key.app-manager-kafka-api-key.secret}";
  Bootstrap Servers: ${confluent_kafka_cluster.standard.bootstrap_endpoint}
  Schema Registry URL: ${data.confluent_schema_registry_cluster.sr-cluster.rest_endpoint}
  Schema Registry Auth: "${confluent_api_key.app-manager-schema-registry-api-key.id}:${confluent_api_key.app-manager-schema-registry-api-key.secret}"

------------------------------
   DATABASE & KMS
------------------------------
  RDS Endpoint: ${aws_db_instance.postgres_db.endpoint}
  KMS Key ARN:  ${aws_kms_key.kms_key.arn}

------------------------------
   SENSITIVE / PRIVATE KEYS
------------------------------
  PrivateKey: ${local.private_key_no_headers}

  EOT

  sensitive = true
}

output "ecs-service-restart-command" {
  value = "aws ecs update-service --cluster ${aws_ecs_cluster.ecs_cluster.name} --service payment-app-service --force-new-deployment --region ${var.cloud_region}"
}

# Create destroy.sh file based on variables used in this script
resource "local_file" "destroy_sh" {
  count    = local.is_windows ? 0 : 1
  filename = "./demo-destroy.sh"
  content  = <<-EOT
    confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --environment ${confluent_environment.staging.id}
    confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --permanent --environment ${confluent_environment.staging.id}
    terraform destroy --auto-approve
  EOT
  depends_on = [
    random_id.env_display_id
  ]
}

resource "local_file" "destroy_bat" {
  count    = local.is_windows ? 1 : 0
  filename = "./demo-destroy.bat"
  content  = <<-EOT
    confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --environment ${confluent_environment.staging.id}
    confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --permanent --environment ${confluent_environment.staging.id}
    terraform destroy --auto-approve
  EOT
  depends_on = [
    random_id.env_display_id
  ]
}
