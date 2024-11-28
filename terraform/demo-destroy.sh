aws ecr delete-repository --repository-name shiftleft-payment-app-repo-844e795b --force
aws ecr delete-repository --repository-name shiftleft-dbfeeder-app-repo-844e795b --force
terraform destroy -var="local_architecture=$ARCH" --auto-approve
