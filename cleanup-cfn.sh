#!/bin/bash

# AWS RAG Laboratory - CloudFormation Cleanup Script
# This script removes all resources created by the CloudFormation stack

set -e

# Configuration
STACK_NAME="RAG-Stack-CFN"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🧹 Cleaning up AWS RAG Laboratory${NC}"
echo "=================================================="

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured."
    exit 1
fi

# Confirm deletion
echo -e "${YELLOW}⚠️  This will delete the CloudFormation stack '$STACK_NAME' and all associated resources.${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled by user"
    exit 0
fi

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" &> /dev/null; then
    echo "ℹ️  Stack '$STACK_NAME' not found. Nothing to clean up."
    exit 0
fi

echo -e "${BLUE}📦 Deleting CloudFormation stack: $STACK_NAME${NC}"
aws cloudformation delete-stack --stack-name "$STACK_NAME"

echo -e "${BLUE}⏳ Waiting for stack deletion to complete...${NC}"
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"

echo ""
echo -e "${GREEN}🧹 Cleanup completed successfully!${NC}"
echo ""
echo "✅ All resources have been removed:"
echo "   - EC2 Instance"
echo "   - Security Group"
echo "   - SSH Key Pair"
echo ""
echo "💡 Check AWS Console to verify all resources are removed."
