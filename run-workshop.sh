#!/bin/bash

# Workshop Docker Environment Runner
set -e

echo "🚀 Starting Online Retailer Flink Demo Workshop..."
echo "🏗️  Building workshop environment..."

# Set platform-specific environment variables
export AWS_CREDENTIALS_PATH="$HOME/.aws"
export DOCKER_SOCK="/var/run/docker.sock"

# Build the workshop container
docker-compose -f build/docker-compose.workshop.yml build

echo "🚀 Starting workshop environment..."
echo ""
echo "This will start a container with all required tools:"
echo "  ✅ Terraform"
echo "  ✅ AWS CLI"
echo "  ✅ Confluent CLI"
echo "  ✅ PostgreSQL Client"
echo "  ✅ Git"
echo "  ✅ Docker CLI"
echo ""
echo "Your AWS credentials and workshop files will be available inside the container."
echo ""
echo "To exit the workshop environment, type 'exit'"
echo ""

# Run the workshop container interactively
docker-compose -f build/docker-compose.workshop.yml run --rm workshop
