@echo off
REM Batch script for Windows deployment
REM Equivalent to demo-provision.sh

REM Detect local machine architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set ARCH=amd64
) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set ARCH=arm64
) else (
    set ARCH=386
)

echo Detected architecture: %ARCH%

REM Run Terraform with the detected architecture
echo Initializing Terraform...
terraform init
if %ERRORLEVEL% neq 0 (
    echo Terraform init failed
    exit /b %ERRORLEVEL%
)

echo Applying Terraform configuration...
terraform apply -var="local_architecture=%ARCH%" --auto-approve
if %ERRORLEVEL% neq 0 (
    echo Terraform apply failed
    exit /b %ERRORLEVEL%
)

echo Deployment completed successfully!
