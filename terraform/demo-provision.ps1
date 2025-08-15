# PowerShell script for Windows deployment
# Equivalent to demo-provision.sh

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

# Run Terraform with the detected architecture
Write-Host "Initializing Terraform..."
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Error "Terraform init failed"
    exit $LASTEXITCODE
}

Write-Host "Applying Terraform configuration..."
terraform apply -var="local_architecture=$ARCH" --auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Error "Terraform apply failed"
    exit $LASTEXITCODE
}

Write-Host "Deployment completed successfully!"
