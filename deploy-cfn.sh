#!/bin/bash

# AWS RAG Laboratory - CloudFormation Deployment Script
# This script creates the SSH key, then deploys the complete RAG infrastructure using CloudFormation

set -e

# Configuration
STACK_NAME="RAG-Stack-CFN"
TEMPLATE_FILE="rag-cfn.yaml"
KEY_NAME="RAG-Key-CFN"
KEY_FILE="RAG-Key-CFN.pem"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔑 Creating SSH Key Pair: $KEY_NAME${NC}"
# Delete key if it already exists (AWS and local)
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
    aws ec2 delete-key-pair --key-name "$KEY_NAME"
    echo "Removed existing AWS key pair: $KEY_NAME"
fi
if [ -f "$KEY_FILE" ]; then
    rm -f "$KEY_FILE"
    echo "Removed existing local key file: $KEY_FILE"
fi
# Create new key pair
aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"
chmod 400 "$KEY_FILE"
echo "Key pair created and saved as $KEY_FILE"

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
