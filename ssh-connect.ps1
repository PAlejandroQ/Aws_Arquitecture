# AWS RAG Laboratory - SSH Connect Script (PowerShell)
# This script retrieves the public IP from the CloudFormation stack, sets it as an environment variable, and connects via SSH

$STACK_NAME = "RAG-Stack-CFN"
$KEY_FILE = "RAG-Key-CFN.pem"
$ENV_VAR_NAME = "RAG_PUBLIC_IP"

function Write-Color($Text, $Color) {
    Write-Host $Text -ForegroundColor $Color
}

function Fix-KeyPermissions($KeyFile) {
    Write-Color "🔒 Restricting permissions for '$KeyFile' (Windows security check)..." Yellow
    
    # 1. Get the current, fully qualified username (e.g., DESKTOP-ABC\vitor)
    $username = (whoami).Trim()
    
    # 2. Disable inheritance and remove all existing permissions
    # Note: Using /inheritance:r for reset
    $resultClear = icacls $KeyFile /inheritance:r
    if ($LASTEXITCODE -ne 0) {
        Write-Color "❌ Failed to clear existing permissions using icacls." Red
        Write-Color $resultClear Red # Display icacls output for debugging
        return $false
    }

    # 3. Grant Read (R) permission exclusively to the current user
    # Note: Using :R is sufficient and safer than :F (Full control)
    $resultGrant = icacls $KeyFile /grant:r "$username`:R"
    if ($LASTEXITCODE -ne 0) {
        Write-Color "❌ Failed to grant exclusive Read permission to '$username'." Red
        Write-Color $resultGrant Red # Display icacls output for debugging
        return $false
    }
    
    Write-Color "✅ Permissions restricted successfully." Green
    return $true
}


# Check prerequisites
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Color "❌ AWS CLI is not installed. Please install it first." Red
    exit 1
}
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Color "❌ OpenSSH is not installed or not in PATH. Please install it first." Red
    exit 1
}
if (-not (Test-Path $KEY_FILE)) {
    Write-Color "❌ SSH key file '$KEY_FILE' not found." Red
    exit 1
}

## NOVO PASSO PARA WINDOWS
# if (Fix-KeyPermissions $KEY_FILE -eq $false) {
#     Write-Color "🔴 Cannot continue due to security permission error." Red
#     exit 1
# }

# Get public IP from CloudFormation stack outputs
try {
    $PUBLIC_IP = aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" --output text
    if ([string]::IsNullOrWhiteSpace($PUBLIC_IP) -or $PUBLIC_IP -eq 'None') {
        Write-Color "❌ Could not retrieve public IP from stack outputs." Red
        exit 1
    }
} catch {
    Write-Color "❌ Error retrieving public IP from CloudFormation." Red
    exit 1
}

# Set environment variable for this session
Set-Item -Path "Env:\$ENV_VAR_NAME" -Value $PUBLIC_IP -Force
Write-Color "✅ Public IP retrieved: $PUBLIC_IP" Green
Write-Host "Environment variable set: `$env:$ENV_VAR_NAME = $PUBLIC_IP"

# Connect via SSH
Write-Color "🔗 Connecting via SSH..." Blue
ssh -i $KEY_FILE ubuntu@$PUBLIC_IP
