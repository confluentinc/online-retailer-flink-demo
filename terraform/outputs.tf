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

output "redshift-output" {
  value = var.data_warehouse == "redshift" ? module.redshift[0].dwh-output : null
}

# Create destroy.sh file based on variables used in this script
resource "local_file" "destroy_sh" {
  filename = "./demo-destroy.sh"
  content  = <<-EOT
#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Configuration
ENVIRONMENT_ID="${confluent_environment.staging.id}"
PAYMENT_REPO="${aws_ecr_repository.payment_app_repo.name}"
DBFEEDER_REPO="${aws_ecr_repository.dbfeeder_app_repo.name}"
REGION="${var.cloud_region}"
SCRIPT_NAME="demo-destroy.sh"

echo -e "$${GREEN}🗑️  Starting Online Retailer Demo Cleanup$${NC}"
echo "============================================================"
echo ""

# Function to retry commands with backoff
retry_command() {
    local cmd="$$1"
    local description="$$2"
    local max_attempts=3
    local delay=5

    for attempt in $$(seq 1 $$max_attempts); do
        echo -e "$${BLUE}Attempt $$attempt/$$max_attempts: $$description$${NC}"
        if eval "$$cmd" 2>/dev/null; then
            echo -e "$${GREEN}✅ $$description completed successfully$${NC}"
            return 0
        else
            if [ $$attempt -eq $$max_attempts ]; then
                echo -e "$${RED}❌ $$description failed after $$max_attempts attempts$${NC}"
                return 1
            else
                echo -e "$${YELLOW}⚠️  $$description failed, retrying in $$delay seconds...$${NC}"
                sleep $$delay
                delay=$$((delay * 2))
            fi
        fi
    done
}

# Function to check if schema references exist
check_schema_references() {
    echo -e "$${BLUE}Checking for schema references to CSFLE_Key...$${NC}"

    # List all schemas that might reference the CSFLE key
    local schemas_with_refs=$$(confluent schema-registry schema list --environment $$ENVIRONMENT_ID 2>/dev/null | grep -E "payments-value|orders-value|customers-value" || true)

    if [ -n "$$schemas_with_refs" ]; then
        echo -e "$${YELLOW}Found schemas with potential CSFLE references:$${NC}"
        echo "$$schemas_with_refs"
        return 1
    else
        echo -e "$${GREEN}No schema references found$${NC}"
        return 0
    fi
}

# Function to get all subjects with DEKs
get_subjects_with_deks() {
    confluent schema-registry dek subject list --kek-name CSFLE_Key --environment $$ENVIRONMENT_ID 2>/dev/null || echo ""
}

# Function to delete DEKs for a specific subject
delete_dek_for_subject() {
    local subject="$$1"
    echo -e "$${BLUE}Deleting DEK for subject: $$subject$${NC}"

    # First try regular delete
    if confluent schema-registry dek delete --kek-name CSFLE_Key --subject "$$subject" --force --environment $$ENVIRONMENT_ID 2>/dev/null; then
        echo -e "$${GREEN}✅ Regular delete successful for $$subject$${NC}"
    else
        echo -e "$${YELLOW}⚠️  Regular delete failed for $$subject$${NC}"
    fi

    # Then try permanent delete
    if confluent schema-registry dek delete --kek-name CSFLE_Key --subject "$$subject" --force --permanent --environment $$ENVIRONMENT_ID 2>/dev/null; then
        echo -e "$${GREEN}✅ Permanent delete successful for $$subject$${NC}"
    else
        echo -e "$${YELLOW}⚠️  Permanent delete failed for $$subject$${NC}"
    fi
}

# Function to cleanup CSFLE resources
cleanup_csfle() {
    echo -e "$${BLUE}Cleaning up CSFLE resources...$${NC}"

    # List all DEK subjects first
    echo -e "$${BLUE}Listing current DEK subjects for CSFLE_Key...$${NC}"
    local all_deks=$$(confluent schema-registry dek subject list --kek-name CSFLE_Key --environment $$ENVIRONMENT_ID 2>/dev/null || echo "")

    if [ -n "$$all_deks" ]; then
        echo -e "$${YELLOW}Found DEKs:$${NC}"
        echo "$$all_deks"
    else
        echo -e "$${GREEN}No DEKs found for CSFLE_Key$${NC}"
    fi

    # Get all subjects with DEKs
    local subjects=$$(get_subjects_with_deks)

    if [ -n "$$subjects" ]; then
        echo -e "$${BLUE}Found subjects with DEKs:$${NC}"
        echo "$$subjects"
        echo ""

        # Delete DEKs for each discovered subject
        while IFS= read -r subject; do
            if [ -n "$$subject" ]; then
                delete_dek_for_subject "$$subject"
            fi
        done <<< "$$subjects"
    fi

    # Also try common demo subjects that might not show up in the list
    echo -e "$${BLUE}Trying cleanup for common demo subjects...$${NC}"
    for subject in "payments-value" "orders-value" "customers-value" "products-value"; do
        echo -e "$${BLUE}Attempting cleanup for $$subject...$${NC}"
        delete_dek_for_subject "$$subject"
    done

    # Wait for propagation
    echo -e "$${BLUE}Waiting 10 seconds for propagation...$${NC}"
    sleep 10

    # Check final status
    echo -e "$${BLUE}Checking remaining DEK subjects...$${NC}"
    local remaining_deks=$$(confluent schema-registry dek subject list --kek-name CSFLE_Key --environment $$ENVIRONMENT_ID 2>/dev/null || echo "")

    if [ -z "$$remaining_deks" ]; then
        echo -e "$${GREEN}✅ All DEKs cleaned up successfully!$${NC}"

        # Try to delete the KEK itself
        echo -e "$${BLUE}Attempting to delete CSFLE_Key KEK...$${NC}"
        if confluent schema-registry kek delete CSFLE_Key --environment $$ENVIRONMENT_ID --force 2>/dev/null; then
            echo -e "$${GREEN}✅ CSFLE_Key KEK deleted successfully!$${NC}"
        else
            echo -e "$${YELLOW}⚠️  KEK deletion failed - Terraform will handle it$${NC}"
        fi

        return 0
    else
        echo -e "$${YELLOW}⚠️  Some DEKs may still exist:$${NC}"
        echo "$$remaining_deks"
        echo -e "$${YELLOW}💡 This might cause terraform destroy issues$${NC}"
        echo -e "$${YELLOW}💡 You may need to manually clean up in Confluent Cloud UI$${NC}"
        return 1
    fi
}

# Function to cleanup ECR repositories
cleanup_ecr() {
    echo -e "$${BLUE}Cleaning up ECR repositories...$${NC}"

    retry_command "aws ecr delete-repository --repository-name $$PAYMENT_REPO --force --region $$REGION" "Delete payments ECR repository"
    local payment_result=$$?

    retry_command "aws ecr delete-repository --repository-name $$DBFEEDER_REPO --force --region $$REGION" "Delete dbfeeder ECR repository"
    local dbfeeder_result=$$?

    if [ $$payment_result -eq 0 ] && [ $$dbfeeder_result -eq 0 ]; then
        echo -e "$${GREEN}✅ ECR repositories cleaned up successfully$${NC}"
        return 0
    else
        echo -e "$${YELLOW}⚠️  Some ECR repositories may not have been deleted$${NC}"
        return 1
    fi
}

# Function to run terraform destroy
run_terraform_destroy() {
    echo -e "$${BLUE}Running Terraform destroy...$${NC}"

    if terraform destroy -var="local_architecture=$$ARCH" --auto-approve; then
        echo -e "$${GREEN}✅ Terraform destroy completed successfully$${NC}"
        return 0
    else
        echo -e "$${RED}❌ Terraform destroy failed$${NC}"
        return 1
    fi
}

# Main cleanup execution
main() {
    local cleanup_success=true

    # Step 1: CSFLE cleanup
    if ! cleanup_csfle; then
        echo -e "$${YELLOW}⚠️  CSFLE cleanup had issues, but continuing...$${NC}"
        cleanup_success=false
    fi

    echo ""

    # Step 2: ECR cleanup
    if ! cleanup_ecr; then
        echo -e "$${YELLOW}⚠️  ECR cleanup had issues, but continuing...$${NC}"
        cleanup_success=false
    fi

    echo ""

    # Step 3: Terraform destroy
    if ! run_terraform_destroy; then
        echo -e "$${RED}❌ Terraform destroy failed - stopping cleanup$${NC}"
        cleanup_success=false
    fi

    echo ""
    echo "============================================================"

    if [ "$$cleanup_success" = true ]; then
        echo -e "$${GREEN}🎉 Cleanup completed successfully!$${NC}"
        echo -e "$${BLUE}Removing cleanup script...$${NC}"
        rm -f "$$SCRIPT_NAME"
        echo -e "$${GREEN}✅ All done!$${NC}"
        exit 0
    else
        echo -e "$${YELLOW}⚠️  Cleanup completed with some issues$${NC}"
        echo -e "$${YELLOW}💡 Check the output above for details$${NC}"
        echo -e "$${YELLOW}📝 Keeping cleanup script for retry: ./$$SCRIPT_NAME$${NC}"
        echo ""
        echo -e "$${BLUE}To retry cleanup:$${NC}"
        echo "  ./$$SCRIPT_NAME"
        echo ""
        echo -e "$${BLUE}To force remove script:$${NC}"
        echo "  rm -f $$SCRIPT_NAME"
        exit 1
    fi
}

# Check prerequisites
if ! command -v confluent &> /dev/null; then
    echo -e "$${RED}❌ Confluent CLI not found. Please ensure you're running this in the workshop container.$${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "$${RED}❌ AWS CLI not found. Please ensure you're running this in the workshop container.$${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "$${RED}❌ Terraform not found. Please ensure you're running this in the workshop container.$${NC}"
    exit 1
fi

# Run main cleanup
main
  EOT
  depends_on = [
    random_id.env_display_id
  ]
}
