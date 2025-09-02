#!/bin/bash
set -e


# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color


echo -e "${GREEN}🚀 Online Retailer Flink Demo - Workshop Environment${NC}"
echo "============================================================"


# Fix line endings for all text files (Windows compatibility)
echo -e "${BLUE}Checking for Windows line ending issues...${NC}"
echo -e "${YELLOW}Found files with potential line ending issues:${NC}"
find /workspace -type f \( -name "*.sh" -o -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.md" -o -name "*.txt" -o -name "*.py" \) -print
echo ""
echo -e "${BLUE}Fixing line endings for all text files...${NC}"
find /workspace -type f \( -name "*.sh" -o -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.md" -o -name "*.txt" -o -name "*.py" \) -exec dos2unix {} \; 2>/dev/null || true
echo -e "${GREEN}✅ Line endings fixed for all text files${NC}"
echo ""


# Check Docker daemon connectivity
echo -e "${BLUE}Checking Docker daemon connectivity...${NC}"
if docker info >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker daemon is accessible${NC}"
    echo -e "${BLUE}Docker version: ${NC}$(docker --version)"
else
    echo -e "${RED}❌ Docker daemon is not accessible${NC}"
    echo -e "${YELLOW}Current DOCKER_HOST: ${DOCKER_HOST:-unix:///var/run/docker.sock}${NC}"
    echo -e "${YELLOW}Socket file exists: $([ -S /var/run/docker.sock ] && echo "YES" || echo "NO")${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting for Windows:${NC}"
    echo -e "${YELLOW}1. Ensure Docker Desktop is running${NC}"
    echo -e "${YELLOW}2. Check Docker Desktop → Settings → General → 'Use WSL 2 based engine'${NC}"
    echo -e "${YELLOW}3. If socket mounting fails, edit docker-compose.windows.yml:${NC}"
    echo -e "${YELLOW}   - Comment out the socket volume line${NC}"
    echo -e "${YELLOW}   - Uncomment: DOCKER_HOST=tcp://host.docker.internal:2375${NC}"
    echo -e "${YELLOW}   - Enable Docker Desktop → Settings → General → 'Expose daemon on tcp://localhost:2375'${NC}"
fi
echo ""


echo -e "${BLUE}Available tools:${NC}"
echo "  ✅ Terraform: $(terraform version | head -1)"
echo "  ✅ AWS CLI: $(aws --version)"
echo "  ✅ Confluent CLI: $(confluent version | head -1)"
echo "  ✅ PostgreSQL Client: $(psql --version)"
echo "  ✅ Git: $(git --version)"
echo "  ✅ Docker CLI: $(docker --version 2>/dev/null || echo "Docker CLI installed (requires host Docker socket)")"
echo "  ✅ Additional tools: jq, vim, tree, make, dos2unix"
echo ""
echo -e "${BLUE}📁 Current directory:${NC} $(pwd)"
echo -e "${BLUE}📂 Workshop files:${NC} /workspace"
echo ""

# Check if AWS credentials are configured
if [ -f "/root/.aws/credentials" ] || [ -n "$AWS_ACCESS_KEY_ID" ]; then
   echo -e "${GREEN}✅ AWS credentials detected${NC}"
else
   echo -e "${YELLOW}⚠️  AWS credentials not found. Run: aws configure${NC}"
fi

# Check if Confluent CLI is logged in
echo -e "${BLUE}Checking Confluent CLI login status...${NC}"
if confluent auth list >/dev/null 2>&1; then
   echo -e "${GREEN}✅ Confluent CLI is logged in${NC}"
else
   echo -e "${YELLOW}⚠️  Confluent CLI not logged in. Run: confluent login${NC}"
   echo -e "${YELLOW}💡 You'll need your Confluent Cloud API Key and Secret${NC}"
fi


# Check if we are in the workshop directory
if [ -f "terraform/terraform.tfvars" ]; then
   echo -e "${GREEN}✅ Workshop environment ready${NC}"
else
   echo -e "${YELLOW}💡 Navigate to terraform directory: cd terraform${NC}"
fi

echo ""
echo -e "${BLUE}Quick start commands:${NC}"
echo "  🔧 aws configure      - Configure AWS credentials"
echo "  🔗 confluent login    - Login to Confluent Cloud"
echo "  📁 cd terraform       - Navigate to terraform directory"
echo "  🚀 terraform init     - Initialize terraform"
echo "  🔧 dos2unix <file>    - Fix Windows line endings in shell scripts"
echo "  🧹 exit               - Exit the container"
echo ""

# If no arguments or if bash/sh is requested, start bash
if [ $# -eq 0 ] || [ "$1" = "bash" ] || [ "$1" = "sh" ]; then
   exec /bin/bash
else
   # Use exec with the full command line
   exec "$@"
fi
