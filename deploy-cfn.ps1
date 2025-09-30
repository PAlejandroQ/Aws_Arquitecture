# AWS RAG Laboratory - CloudFormation Deployment Script (PowerShell)
# This script creates the SSH key, then deploys the complete RAG infrastructure using CloudFormation

$STACK_NAME = "RAG-Stack-CFN"
$TEMPLATE_FILE = "rag-cfn.yaml"
$KEY_NAME = "RAG-Key-CFN"
$KEY_FILE = "RAG-Key-CFN.pem"

function Write-Color($Text, $Color) {
    Write-Host $Text -ForegroundColor $Color
}

Write-Color "🔑 Creating SSH Key Pair: $KEY_NAME" Blue
# Delete key if it already exists (AWS and local)
$keyExists = $false
try {
    aws ec2 describe-key-pairs --key-names $KEY_NAME | Out-Null
    $keyExists = $true
} catch {}
if ($keyExists) {
    aws ec2 delete-key-pair --key-name $KEY_NAME
    Write-Host "Removed existing AWS key pair: $KEY_NAME"
}
if (Test-Path $KEY_FILE) {
    Remove-Item $KEY_FILE -Force
    Write-Host "Removed existing local key file: $KEY_FILE"
}
# Create new key pair
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_FILE
# Set permissions (Windows: just warn if not possible)
try {
    icacls $KEY_FILE /inheritance:r /grant:r "$($env:USERNAME):(R)" | Out-Null
} catch {}
Write-Host "Key pair created and saved as $KEY_FILE"

Write-Color "🚀 Deploying AWS RAG Laboratory via CloudFormation" Blue
Write-Host "=================================================="

# Check prerequisites
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Color "❌ AWS CLI is not installed. Please install it first." Red
    exit 1
}

try {
    aws sts get-caller-identity | Out-Null
} catch {
    Write-Color "❌ AWS CLI is not configured. Please run 'aws configure' first." Red
    exit 1
}

if (-not (Test-Path $TEMPLATE_FILE)) {
    Write-Color "❌ Template file '$TEMPLATE_FILE' not found." Red
    exit 1
}

Write-Host "✅ Prerequisites check passed"

# Deploy CloudFormation stack
Write-Color "📦 Deploying CloudFormation stack: $STACK_NAME" Blue
aws cloudformation deploy --template-file $TEMPLATE_FILE --stack-name $STACK_NAME --capabilities CAPABILITY_NAMED_IAM

Write-Host ""
Write-Color "🎉 Deployment completed successfully!" Green
Write-Host ""
Write-Host "📋 Stack Information:"
Write-Host "   Stack Name: $STACK_NAME"
Write-Host "   Template: $TEMPLATE_FILE"
Write-Host ""
Write-Host "🔗 Useful commands:"
Write-Host "   View stack: aws cloudformation describe-stacks --stack-name $STACK_NAME"
Write-Host "   Get outputs: aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs'"
Write-Host "   Cleanup: ./cleanup-cfn.ps1"
Write-Host ""
Write-Host "⏱️  The RAG application may take 5-10 minutes to fully initialize."

