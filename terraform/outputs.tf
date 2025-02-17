output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.staging.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.standard.id}
  Flink Compute pool ID: ${confluent_flink_compute_pool.flinkpool-main.id}

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
  ${confluent_service_account.app-manager.display_name}:                     ${confluent_service_account.app-manager.id}
  ${confluent_service_account.app-manager.display_name}'s Kafka API Key:     "${confluent_api_key.app-manager-kafka-api-key.id}"
  ${confluent_service_account.app-manager.display_name}'s Kafka API Secret:  "${confluent_api_key.app-manager-kafka-api-key.secret}"


  Service Accounts and their Flink management API Keys (API Keys inherit the permissions granted to the owner):
  ${confluent_service_account.app-manager.display_name}:                     ${confluent_service_account.app-manager.id}
  ${confluent_service_account.app-manager.display_name}'s Flink management API Key:     "${confluent_api_key.app-manager-flink-api-key.id}"
  ${confluent_service_account.app-manager.display_name}'s Flink management API Secret:  "${confluent_api_key.app-manager-flink-api-key.secret}"


  sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="${confluent_api_key.app-manager-kafka-api-key.id}" password="${confluent_api_key.app-manager-kafka-api-key.secret}";
  bootstrap.servers=${confluent_kafka_cluster.standard.bootstrap_endpoint}
  schema.registry.url= ${data.confluent_schema_registry_cluster.sr-cluster.rest_endpoint}
  schema.registry.basic.auth.user.info= "${confluent_api_key.app-manager-schema-registry-api-key.id}:${confluent_api_key.app-manager-schema-registry-api-key.secret}"

  RDS Endpoint: ${aws_db_instance.postgres_db.endpoint}
  KMS Key ARN: ${aws_kms_key.kms_key.arn}

  PrivateKey: ${local.private_key_no_headers}

  EOT

  sensitive = true
}

output "ecs-service-restart-command" {
  value = "aws ecs update-service --cluster ${aws_ecs_cluster.ecs_cluster.name} --service payment-app-service --force-new-deployment --region ${var.cloud_region}"
}

output "redshift-output" {
  value = var.data_warehouse == "redshift" ? module.redshift[0].dwh-output : null
}

# Create destroy.sh file based on variables used in this script
resource "local_file" "destroy_sh" {
  filename = "./demo-destroy.sh"
  content  = <<-EOT
    aws ecr delete-repository --repository-name ${aws_ecr_repository.payment_app_repo.name} --force --region ${var.cloud_region}
    aws ecr delete-repository --repository-name ${aws_ecr_repository.dbfeeder_app_repo.name} --force --region ${var.cloud_region}
    terraform destroy -var="local_architecture=$ARCH" --auto-approve
  EOT 
  }

# Create USECASE 4 terraform varaible file based on variables used in this script
resource "local_file" "usecase4_terraform_var_file" {
  filename = "../Usecase4/flink_terraform/terraform.tfvars"
  content  = <<-EOT
  confluent_cloud_api_key = "${var.confluent_cloud_api_key}"
  confluent_cloud_api_secret = "${var.confluent_cloud_api_secret}"
  confluent_cloud_environment_id = "${confluent_environment.staging.id}"
  confluent_cloud_cluster_id = "${confluent_kafka_cluster.standard.id}"
  demo_compute_pool_id = "${confluent_flink_compute_pool.flinkpool-main.id}"
  confluent_cloud_service_account_id = "${confluent_service_account.app-manager.id}"
  cloud_region = "${var.cloud_region}"
  flink_management_api_key= "${confluent_api_key.app-manager-flink-api-key.id}"
  flink_management_api_key_secret= "${confluent_api_key.app-manager-flink-api-key.secret}"
  flink_statement_stopped=false
  EOT 
  }
