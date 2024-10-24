aws ecr delete-repository --repository-name dbfeeder-app-repo --force
aws ecr delete-repository --repository-name payment-app-repo --force
terraform destroy --auto-approve