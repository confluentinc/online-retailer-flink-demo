@echo off
REM Workshop Docker Environment Runner for Windows Command Prompt

echo [*] Starting Online Retailer Flink Demo Workshop...
echo [+] Building workshop environment...

REM Build the workshop container (Windows-specific compose file)
docker-compose -f build\docker-compose.windows.yml build

echo.
echo [*] Starting workshop environment...
echo.
echo This will start a container with all required tools:
echo   [OK] Terraform
echo   [OK] AWS CLI
echo   [OK] Confluent CLI
echo   [OK] PostgreSQL Client
echo   [OK] Git
echo   [OK] Docker CLI
echo.
echo Your AWS credentials and workshop files will be available inside the container.
echo.
echo To exit the workshop environment, type 'exit'
echo.

REM Run the workshop container interactively (Windows-specific compose file)
docker-compose -f build\docker-compose.windows.yml run --rm workshop
