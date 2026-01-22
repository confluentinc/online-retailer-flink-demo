# AWS provider configuration
# This is required to manage AWS resources. The region is dynamically set via a variable.
provider "aws" {
  region = var.cloud_region
  # Default tags to apply to all resources
  default_tags {
    tags = {
      Created_by  = "Shift-left Terraform script"
      Project     = "Shift-left Demo"
      owner_email = var.email
    }
  }
}

# Here we are using the Confluent provider for managing Confluent Cloud resources.
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.32.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Local provider for accessing and managing local system resources.
# This is useful for tasks like rendering templates, reading local files, etc.
provider "local" {}

# TLS provider for generating SSH key pairs.
provider "tls" {}

data "aws_ecr_authorization_token" "ecr" {}

data "external" "uid_unix" {
  count   = local.is_windows ? 0 : 1
  program = ["/bin/sh", "-c", "printf '{\"uid\":\"%s\"}' \"$(id -u)\""]
}

data "external" "detect_socket_windows" {
  count   = local.is_windows ? 1 : 0
  program = ["powershell.exe", "-NoProfile", "-Command", <<-EOF
    $ErrorActionPreference = 'SilentlyContinue'
    
    # Check sockets in priority order
    # Docker Desktop named pipe
    if (Test-Path "//./pipe/docker_engine") {
      Write-Output '{"host":"npipe:////./pipe/docker_engine"}'
      exit 0
    }
    
    # Podman named pipe (default machine)
    if (Test-Path "//./pipe/podman-machine-default") {
      Write-Output '{"host":"npipe:////./pipe/podman-machine-default"}'
      exit 0
    }
    
    # Podman named pipe (generic)
    if (Test-Path "//./pipe/podman") {
      Write-Output '{"host":"npipe:////./pipe/podman"}'
      exit 0
    }
    
    # Rancher Desktop named pipe
    if (Test-Path "//./pipe/rancher-desktop-docker") {
      Write-Output '{"host":"npipe:////./pipe/rancher-desktop-docker"}'
      exit 0
    }
    
    # Default to Docker Desktop pipe
    Write-Output '{"host":"npipe:////./pipe/docker_engine"}'
  EOF
  ]
}



# Simplified: Check common socket locations without find
data "external" "detect_socket" {
  count   = local.is_windows ? 0 : 1
  program = ["/bin/sh", "-c", <<-EOF
    set -e
    uid="$(id -u)"
    
    # Check sockets in priority order
    if [ -S "$HOME/.colima/default/docker.sock" ]; then
      printf '{"host":"unix://%s/.colima/default/docker.sock"}' "$HOME"
    elif [ -S "/run/user/$uid/podman/podman.sock" ]; then
      printf '{"host":"unix:///run/user/%s/podman/podman.sock"}' "$uid"
    elif [ -S "/run/podman/podman.sock" ]; then
      printf '{"host":"unix:///run/podman/podman.sock"}'
    else
      # Docker Desktop first for Docker logic
      if [ -S "/var/run/docker.sock" ]; then
        printf '{"host":"unix:///var/run/docker.sock"}'
      # Docker Desktop alternate per-user path
      elif [ -S "$HOME/.docker/run/docker.sock" ]; then
        printf '{"host":"unix://%s/.docker/run/docker.sock"}' "$HOME"
      else
        # Try to find Podman macOS socket (does not change existing Podman logic priority)
        sock=$(find /var/folders -name "podman-machine-default-api.sock" -type s 2>/dev/null | head -1)
        if [ -n "$sock" ]; then
          printf '{"host":"unix://%s"}' "$sock"
        else
          printf '{"host":"unix:///var/run/docker.sock"}'
        fi
      fi
    fi
  EOF
  ]
}

locals {
  # Get the detected socket from the external script(s)
docker_host = local.is_windows ? data.external.detect_socket_windows[0].result.host : data.external.detect_socket[0].result.host
}

provider "docker" {
  host = local.docker_host
  
  registry_auth {
    address  = replace(data.aws_ecr_authorization_token.ecr.proxy_endpoint, "https://", "")
    username = data.aws_ecr_authorization_token.ecr.user_name
    password = data.aws_ecr_authorization_token.ecr.password
  }
}

output "docker_host" {
  value = local.docker_host
}