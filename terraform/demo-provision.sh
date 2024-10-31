#!/bin/bash

# Detect local machine architecture
ARCH=$(uname -m)

# Run Terraform with the detected architecture
terraform init

terraform apply -var="local_architecture=$ARCH" --auto-approve
