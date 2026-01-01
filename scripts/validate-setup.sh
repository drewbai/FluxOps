#!/bin/bash
# FluxOps Setup Validation Script (Bash version)
# Checks prerequisites and validates configuration

echo "🚀 FluxOps Setup Validation"
echo "=================================================="
echo ""

errors=0
warnings=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Azure CLI
echo -n "Checking Azure CLI..."
if command_exists az; then
    echo -e " ${GREEN}✅ Installed${NC}"
else
    echo -e " ${RED}❌ Not found${NC}"
    echo -e "  ${YELLOW}Install: https://aka.ms/InstallAzureCLI${NC}"
    ((errors++))
fi

# Check Terraform
echo -n "Checking Terraform..."
if command_exists terraform; then
    tf_version=$(terraform version | head -n1)
    echo -e " ${GREEN}✅ Installed ($tf_version)${NC}"
else
    echo -e " ${RED}❌ Not found${NC}"
    echo -e "  ${YELLOW}Install: https://www.terraform.io/downloads${NC}"
    ((errors++))
fi

# Check Python
echo -n "Checking Python..."
if command_exists python3; then
    py_version=$(python3 --version)
    echo -e " ${GREEN}✅ Installed ($py_version)${NC}"
elif command_exists python; then
    py_version=$(python --version)
    echo -e " ${GREEN}✅ Installed ($py_version)${NC}"
else
    echo -e " ${RED}❌ Not found${NC}"
    echo -e "  ${YELLOW}Install: https://www.python.org/downloads/${NC}"
    ((errors++))
fi

# Check Git
echo -n "Checking Git..."
if command_exists git; then
    git_version=$(git --version)
    echo -e " ${GREEN}✅ Installed ($git_version)${NC}"
else
    echo -e " ${RED}❌ Not found${NC}"
    echo -e "  ${YELLOW}Install: https://git-scm.com/downloads${NC}"
    ((errors++))
fi

echo ""
echo -e "${CYAN}Checking Azure Authentication...${NC}"

# Check Azure login
if az account show >/dev/null 2>&1; then
    account_name=$(az account show --query name -o tsv)
    account_id=$(az account show --query id -o tsv)
    user_name=$(az account show --query user.name -o tsv)
    echo -n "Azure Account..."
    echo -e " ${GREEN}✅ Logged in as $user_name${NC}"
    echo -n "Subscription..."
    echo -e " ${GREEN}✅ $account_name ($account_id)${NC}"
else
    echo -n "Azure Authentication..."
    echo -e " ${YELLOW}⚠️  Not logged in${NC}"
    echo -e "  ${YELLOW}Run: az login${NC}"
    ((warnings++))
fi

echo ""
echo -e "${CYAN}Checking Terraform Configuration...${NC}"

# Check if terraform directory exists
if [ -f "infra/terraform/main.tf" ]; then
    echo -n "Terraform files..."
    echo -e " ${GREEN}✅ Found${NC}"
    
    # Check terraform.tfvars
    if [ -f "infra/terraform/terraform.tfvars" ]; then
        echo -n "terraform.tfvars..."
        echo -e " ${GREEN}✅ Found${NC}"
    else
        echo -n "terraform.tfvars..."
        echo -e " ${YELLOW}⚠️  Not found${NC}"
        echo -e "  ${YELLOW}Consider creating from terraform.tfvars.example${NC}"
        ((warnings++))
    fi
    
    # Try Terraform validation
    echo -n "Terraform validation..."
    cd infra/terraform
    if terraform init -backend=false >/dev/null 2>&1 && terraform validate >/dev/null 2>&1; then
        echo -e " ${GREEN}✅ Valid${NC}"
    else
        echo -e " ${RED}❌ Invalid${NC}"
        echo -e "  ${YELLOW}Run 'terraform validate' for details${NC}"
        ((errors++))
    fi
    cd ../..
else
    echo -n "Terraform files..."
    echo -e " ${RED}❌ Not found${NC}"
    ((errors++))
fi

echo ""
echo -e "${CYAN}Checking Python Environment...${NC}"

# Check ML pipeline requirements
if [ -f "src/ml_pipeline/requirements.txt" ]; then
    echo -n "ML Pipeline requirements..."
    echo -e " ${GREEN}✅ Found${NC}"
    
    # Check if virtual environment exists
    if [ -d ".venv" ] || [ -d "venv" ]; then
        echo -n "Virtual environment..."
        echo -e " ${GREEN}✅ Found${NC}"
    else
        echo -n "Virtual environment..."
        echo -e " ${YELLOW}⚠️  Not found${NC}"
        echo -e "  ${YELLOW}Run: python3 -m venv .venv${NC}"
        ((warnings++))
    fi
else
    echo -n "ML Pipeline requirements..."
    echo -e " ${YELLOW}⚠️  Not found${NC}"
    ((warnings++))
fi

# Check Function App requirements
if [ -f "src/function_app/requirements.txt" ]; then
    echo -n "Function App requirements..."
    echo -e " ${GREEN}✅ Found${NC}"
else
    echo -n "Function App requirements..."
    echo -e " ${YELLOW}⚠️  Not found${NC}"
    ((warnings++))
fi

echo ""
echo -e "${CYAN}Checking Documentation...${NC}"

docs=("README.md" "QUICKSTART.md" "docs/IaC_Design.md" "docs/Pipeline_Logic.md" "docs/Case_Study.md")
for doc in "${docs[@]}"; do
    doc_name=$(basename "$doc")
    echo -n "$doc_name..."
    if [ -f "$doc" ]; then
        echo -e " ${GREEN}✅ Found${NC}"
    else
        echo -e " ${YELLOW}⚠️  Missing${NC}"
        ((warnings++))
    fi
done

echo ""
echo "=================================================="
echo -e "${CYAN}Validation Summary${NC}"
echo "=================================================="

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready to deploy.${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Review configuration in infra/terraform/terraform.tfvars"
    echo "2. Run: cd infra/terraform && terraform init"
    echo "3. Run: terraform plan"
    echo "4. Run: terraform apply"
    echo ""
    echo "Or push to GitLab to trigger CI/CD pipeline"
    exit 0
elif [ $errors -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $warnings warning(s) found. Review and proceed.${NC}"
    exit 0
else
    echo -e "${RED}❌ $errors error(s) and $warnings warning(s) found.${NC}"
    echo -e "${RED}Please fix errors before proceeding.${NC}"
    exit 1
fi
