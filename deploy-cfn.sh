#!/bin/bash

# AWS RAG Laboratory - CloudFormation Deployment Script
# This script deploys the complete RAG infrastructure using CloudFormation

set -e

# Configuration
STACK_NAME="RAG-Stack-CFN"
TEMPLATE_FILE="rag-cfn.yaml"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Deploying AWS RAG Laboratory via CloudFormation${NC}"
echo "=================================================="

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Template file '$TEMPLATE_FILE' not found."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Deploy CloudFormation stack
echo -e "${BLUE}📦 Deploying CloudFormation stack: $STACK_NAME${NC}"
aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM

echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo "📋 Stack Information:"
echo "   Stack Name: $STACK_NAME"
echo "   Template: $TEMPLATE_FILE"
echo ""
echo "🔗 Useful commands:"
echo "   View stack: aws cloudformation describe-stacks --stack-name $STACK_NAME"
echo "   Get outputs: aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs'"
echo "   Cleanup: ./cleanup-cfn.sh"
echo ""
echo "⏱️  The RAG application may take 5-10 minutes to fully initialize."
