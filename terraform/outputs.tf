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
    confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --environment ${confluent_environment.staging.id}
    confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --permanent --environment ${confluent_environment.staging.id}
    aws ecr delete-repository --repository-name ${aws_ecr_repository.payment_app_repo.name} --force --region ${var.cloud_region}
    aws ecr delete-repository --repository-name ${aws_ecr_repository.dbfeeder_app_repo.name} --force --region ${var.cloud_region}
    terraform destroy -var="local_architecture=$ARCH" --auto-approve
  EOT
  depends_on = [
    random_id.env_display_id
  ]
}

# Create Windows PowerShell destroy script
resource "local_file" "destroy_ps1" {
  filename = "./demo-destroy.ps1"
  content  = <<-EOT
    # PowerShell script for Windows cleanup
    # Equivalent to demo-destroy.sh

    # Detect local machine architecture
    if ([Environment]::Is64BitOperatingSystem) {
        if ([Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE") -eq "ARM64") {
            $ARCH = "arm64"
        } else {
            $ARCH = "amd64"
        }
    } else {
        $ARCH = "386"
    }

    Write-Host "Detected architecture: $ARCH"
    Write-Host "Starting cleanup process..."

    try {
        Write-Host "Deleting schema registry DEKs..."
        confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --environment ${confluent_environment.staging.id}
        confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --permanent --environment ${confluent_environment.staging.id}

        Write-Host "Deleting ECR repositories..."
        aws ecr delete-repository --repository-name ${aws_ecr_repository.payment_app_repo.name} --force --region ${var.cloud_region}
        aws ecr delete-repository --repository-name ${aws_ecr_repository.dbfeeder_app_repo.name} --force --region ${var.cloud_region}

        Write-Host "Running terraform destroy..."
        terraform destroy -var="local_architecture=$ARCH" --auto-approve

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Cleanup completed successfully!"
        } else {
            Write-Error "Terraform destroy failed with exit code $LASTEXITCODE"
            exit $LASTEXITCODE
        }
    }
    catch {
        Write-Error "An error occurred during cleanup: $_"
        exit 1
    }
  EOT
  depends_on = [
    random_id.env_display_id
  ]
}

# Create Windows batch destroy script
resource "local_file" "destroy_bat" {
  filename = "./demo-destroy.bat"
  content  = <<-EOT
    @echo off
    REM Batch script for Windows cleanup
    REM Equivalent to demo-destroy.sh

    REM Detect local machine architecture
    if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
        set ARCH=amd64
    ) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
        set ARCH=arm64
    ) else (
        set ARCH=386
    )

    echo Detected architecture: %ARCH%
    echo Starting cleanup process...

    echo Deleting schema registry DEKs...
    confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --environment ${confluent_environment.staging.id}
    confluent schema-registry dek delete --kek-name CSFLE_Key --subject payments-value --force --permanent --environment ${confluent_environment.staging.id}

    echo Deleting ECR repositories...
    aws ecr delete-repository --repository-name ${aws_ecr_repository.payment_app_repo.name} --force --region ${var.cloud_region}
    if %ERRORLEVEL% neq 0 echo Warning: Failed to delete payment app repository

    aws ecr delete-repository --repository-name ${aws_ecr_repository.dbfeeder_app_repo.name} --force --region ${var.cloud_region}
    if %ERRORLEVEL% neq 0 echo Warning: Failed to delete dbfeeder app repository

    echo Running terraform destroy...
    terraform destroy -var="local_architecture=%ARCH%" --auto-approve
    if %ERRORLEVEL% neq 0 (
        echo Terraform destroy failed
        exit /b %ERRORLEVEL%
    )

    echo Cleanup completed successfully!
  EOT
  depends_on = [
    random_id.env_display_id
  ]
}
