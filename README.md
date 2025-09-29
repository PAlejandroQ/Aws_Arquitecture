
# AWS RAG Deployment Laboratory - CloudFormation Focus

This laboratory demonstrates Infrastructure as Code (IaC) using AWS CloudFormation to deploy a complete Retrieval-Augmented Generation (RAG) system. Learn how a single YAML template can provision all necessary AWS resources automatically.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Basic understanding of AWS services and CloudFormation concepts

## What is CloudFormation?

**AWS CloudFormation** is AWS's Infrastructure as Code service that allows you to define and provision 
AWS infrastructure using declarative templates. Instead of manually creating resources through the 
console or CLI, you describe what you want in a template, and CloudFormation handles the creation, 
updating, and deletion of resources.

**Important:** When using CloudFormation, you must create the SSH key pair manually before deploying the stack. CloudFormation cannot provide you with the private key file (`.pem`).

### Key Benefits:
- **Declarative**: Describe *what* you want, not *how* to create it
- **Repeatable**: Deploy the same infrastructure consistently
- **Version Controlled**: Templates can be stored in Git
- **Dependency Management**: CloudFormation handles resource dependencies automatically
- **Rollback**: Automatic rollback on deployment failures

```bash
aws ec2 create-key-pair --key-name RAG-Key-CFN --query 'KeyMaterial' --output text > RAG-Key-CFN.pem
chmod 400 RAG-Key-CFN.pem
```
- This creates the key pair in AWS and saves the private key locally for SSH access.

Deploy the complete RAG infrastructure with a single command:

```bash
./deploy-cfn.sh
```

This executes:
```bash
aws cloudformation deploy --template-file rag-cfn.yaml --stack-name RAG-Stack-CFN --capabilities CAPABILITY_NAMED_IAM
```

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User/Client   │────│   Security      │────│   Ubuntu EC2    │
│   (Browser/CLI) │    │   Group (SG)    │    │   Instance      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        │ Docker Compose
                                                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Docker Containers                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │     Ollama      │  │  Elasticsearch  │  │   FastAPI RAG  │ │
│  │   (LLM Server)  │  │ (Vector Store)  │  │     API App     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

- **Port 22** is open for SSH access (using your manually created key)
- **Port 8000** is open to the internet for API access

## CloudFormation Template Deep Dive

Let's break down the `rag-cfn.yaml` template step by step:

### 1. Template Header
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Automated RAG System Deployment on EC2 Ubuntu (Laboratory)'
```
- **AWSTemplateFormatVersion**: Specifies the template format version
- **Description**: Human-readable description of what this template does

### 2. Parameters Section
```yaml
Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
    Description: 'EC2 instance type (Free Tier: t2.micro)'

  KeyName:
    Type: String
    Default: RAG-Key-CFN
    Description: 'Key Pair name for SSH access'

  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id
    Description: 'Latest Ubuntu Server 20.04 LTS AMI'
```
**Parameters** allow customization without changing the template:
- **InstanceType**: What size EC2 instance to use (t2.micro for Free Tier)
- **KeyName**: Name for the SSH key pair
- **LatestAmiId**: Uses AWS Systems Manager Parameter Store to get the latest Ubuntu AMI automatically

### 3. Resources Section - The Heart of CloudFormation

#### 3.1 SSH Key Pair
```yaml
RAGKeyPair:
  Type: AWS::EC2::KeyPair
  Properties:
    KeyName: !Ref KeyName
```
- **Type**: Specifies this is an EC2 Key Pair resource
- **Properties**: Configuration for the resource
- **!Ref KeyName**: References the KeyName parameter value

#### 3.2 Security Group (Virtual Firewall)
```yaml
RAGSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: 'Enable SSH and RAG API access'
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 22
        ToPort: 22
        CidrIp: 0.0.0.0/0
        Description: 'SSH port for administrative access'
      - IpProtocol: tcp
        FromPort: 8000
        ToPort: 8000
        CidrIp: 0.0.0.0/0
        Description: 'API port for RAG service'
```
- **SecurityGroupIngress**: Defines inbound traffic rules
- **CidrIp: 0.0.0.0/0**: Allows access from anywhere (for demo purposes)
- **FromPort/ToPort**: Port ranges (single port when equal)

#### 3.3 EC2 Instance - The Main Compute Resource
```yaml
RAGInstance:
  Type: AWS::EC2::Instance
  Properties:
    InstanceType: !Ref InstanceType
    ImageId: !Ref LatestAmiId
    KeyName: !Ref RAGKeyPair
    SecurityGroupIds:
      - !Ref RAGSecurityGroup
    Tags:
      - Key: Name
        Value: RAG-CFN-Instance
      - Key: Environment
        Value: Lab
      - Key: Project
        Value: RAG-Demo
    UserData: # <-- This is where the magic happens!
```
- **ImageId**: References the Ubuntu AMI parameter
- **KeyName**: References the created key pair
- **SecurityGroupIds**: References the security group
- **Tags**: Metadata for organization and cost tracking

##### UserData - Automated Instance Configuration
The **UserData** property contains a bash script that runs automatically when the instance starts:

```bash
#!/bin/bash
# 1. Update system and install Docker
# 2. Clone the RAG project from GitHub
# 3. Start everything with docker compose up --build -d
```

This script:
1. **Installs Docker** on the Ubuntu instance
2. **Clones** the RAG project from [https://github.com/PAlejandroQ/Puc_RAG.git](https://github.com/PAlejandroQ/Puc_RAG.git)
3. **Starts the application** using `docker compose up --build -d`

### 4. Outputs Section
```yaml
Outputs:
  InstanceId:
    Description: 'EC2 instance ID'
    Value: !Ref RAGInstance
    Export:
      Name: !Sub '${AWS::StackName}-InstanceId'

  PublicIP:
    Description: 'Public IP of the RAG instance'
    Value: !GetAtt RAGInstance.PublicIp
    Export:
      Name: !Sub '${AWS::StackName}-PublicIP'
```
- **Outputs** expose important information after deployment
- **!Ref RAGInstance**: Gets the instance ID
- **!GetAtt RAGInstance.PublicIp**: Gets the public IP address
- **Export**: Makes these values available to other CloudFormation stacks

## Files Description

- `rag-cfn.yaml` - **CloudFormation template** (the star of the show!)
- `setup-rag.sh` - User Data script for automated instance configuration
- `deploy-cfn.sh` - Simple deployment script
- `cleanup-cfn.sh` - Simple cleanup script

## Deployment Process

1. **Create the SSH key pair** (see above)
2. **Deploy the stack** (`./deploy-cfn.sh`)
3. **Wait for the instance to initialize** (5-10 minutes)
4. **Get the public IP**:
   ```bash
   aws cloudformation describe-stacks --stack-name RAG-Stack-CFN --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' --output text
   ```
5. **SSH into the instance**:
   ```bash
   ssh -i RAG-Key-CFN.pem ubuntu@[PUBLIC_IP]
   ```
6. **Test the API** (port 8000 is open):
   ```bash
   # Health check
   curl http://[PUBLIC_IP]:8000/

   # Query document using RAG
   curl -X POST http://[PUBLIC_IP]:8000/query \
     -H "Content-Type: application/json" \
     -d '{"question": "In what case is the spouse's succession inadmissible?"}'
   ```

## Cleanup

Remove all resources with a single command:

```bash
./cleanup-cfn.sh
```

This executes:
```bash
aws cloudformation delete-stack --stack-name RAG-Stack-CFN
```

CloudFormation automatically handles resource deletion in the correct order.

## Key Takeaways

1. **One YAML file** = Complete infrastructure deployment
2. **Declarative approach**: Describe desired state, AWS handles implementation
3. **Dependency management**: CloudFormation creates resources in correct order
4. **Automated cleanup**: Single command removes everything
5. **Version control**: Infrastructure changes can be tracked in Git
6. **Reusable**: Same template can deploy multiple environments

This approach transforms complex multi-step deployments into simple, reliable, and repeatable infrastructure management!