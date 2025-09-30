# AWS RAG Laboratory - CloudFormation Cleanup Script (PowerShell)
# This script removes all resources created by the CloudFormation stack and deletes the SSH key

$STACK_NAME = "RAG-Stack-CFN"
$KEY_NAME = "RAG-Key-CFN"
$KEY_FILE = "RAG-Key-CFN.pem"

function Write-Color($Text, $Color) {
    Write-Host $Text -ForegroundColor $Color
}

Write-Color "🧹 Cleaning up AWS RAG Laboratory" Blue
Write-Host "=================================================="

# Check prerequisites
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Color "❌ AWS CLI is not installed." Red
    exit 1
}

try {
    aws sts get-caller-identity | Out-Null
} catch {
    Write-Color "❌ AWS CLI is not configured." Red
    exit 1
}

# Confirm deletion
Write-Color "⚠️  This will delete the CloudFormation stack '$STACK_NAME' and all associated resources, including the SSH key pair." Yellow
$confirmation = Read-Host "Are you sure you want to continue? (y/N)"
if ($confirmation -notmatch '^[Yy]$') {
    Write-Color "❌ Cleanup cancelled by user" Red
    exit 0
}

# Check if stack exists
$stackExists = $false
try {
    aws cloudformation describe-stacks --stack-name $STACK_NAME | Out-Null
    $stackExists = $true
} catch {}

if (-not $stackExists) {
    Write-Color "ℹ️  Stack '$STACK_NAME' not found. Nothing to clean up." Yellow
} else {
    Write-Color "📦 Deleting CloudFormation stack: $STACK_NAME" Blue
    aws cloudformation delete-stack --stack-name $STACK_NAME
    Write-Color "⏳ Waiting for stack deletion to complete..." Blue
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
}

# Delete AWS key pair
$keyExists = $false
try {
    aws ec2 describe-key-pairs --key-names $KEY_NAME | Out-Null
    $keyExists = $true
} catch {}
if ($keyExists) {
    aws ec2 delete-key-pair --key-name $KEY_NAME
    Write-Host "Deleted AWS key pair: $KEY_NAME"
}
# Delete local key file
if (Test-Path $KEY_FILE) {
    Remove-Item $KEY_FILE -Force
    Write-Host "Deleted local key file: $KEY_FILE"
}

Write-Host ""
Write-Color "🧹 Cleanup completed successfully!" Green
Write-Host ""
Write-Host "✅ All resources have been removed:"
Write-Host "   - EC2 Instance"
Write-Host "   - Security Group"
Write-Host "   - SSH Key Pair (AWS and local)"
Write-Host ""
Write-Host "💡 Check AWS Console to verify all resources are removed."

