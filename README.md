# MicroTodo Infrastructure

This repository contains the Infrastructure as Code (IaC) and Kubernetes configurations for the MicroTodo application, built using Terraform and AWS services.

## 🏗️ Architecture Overview

The infrastructure consists of:

- **AWS EKS Cluster** - Managed Kubernetes service for container orchestration
- **VPC with Multi-AZ Setup** - Secure network isolation across 3 availability zones
- **IAM Roles & Policies** - Secure access management for EKS cluster and worker nodes
- **Remote State Management** - S3 backend with DynamoDB locking for state consistency

## 📁 Repository Structure

```
infrastructure/
├── terraform-bootstrap/     # Bootstrap resources for Terraform state management
│   └── main.tf             # S3 bucket and DynamoDB table for remote state
├── terraform/              # Main infrastructure resources
│   ├── main.tf             # Provider configuration
│   ├── terraform.tf        # Terraform configuration and S3 backend
│   ├── locals.tf           # Local variables and subnet definitions
│   ├── vpc.tf              # VPC, subnets, gateways, and routing
│   ├── iam.tf              # IAM roles and policies for EKS
│   └── eks.tf              # EKS cluster and node group configuration
└── README.md               # This file
```

## 🌐 Infrastructure Components

### VPC Network Architecture
- **CIDR Block**: `10.0.0.0/16`
- **Public Subnets**: 3 subnets across AZs (eu-west-2a, eu-west-2b, eu-west-2c)
  - `10.0.0.0/22`, `10.0.4.0/22`, `10.0.8.0/22`
- **Private Subnets**: 3 subnets across AZs
  - `10.0.12.0/22`, `10.0.16.0/22`, `10.0.20.0/22`
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: Single NAT gateway for private subnet outbound traffic
- **Route Tables**: Separate routing for public and private subnets

### EKS Cluster Configuration
- **Cluster Version**: 1.31
- **Node Group**: 
  - Instance Type: `t3.small`
  - Scaling: Min 1, Desired 2, Max 3 nodes
  - Deployment: Private subnets only
- **Logging**: Enabled for API, audit, authenticator, controller manager, and scheduler
- **Access**: Public endpoint enabled (development setup)

### IAM Security
- **EKS Cluster Role**: Service role for EKS cluster management
- **Node Group Role**: EC2 service role with required policies:
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AmazonEC2ContainerRegistryReadOnly

## 🚀 Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.13
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with necessary permissions for EKS, VPC, IAM, S3, and DynamoDB

### Initial Setup

1. **Bootstrap Terraform State Management**
   ```bash
   cd terraform-bootstrap
   terraform init
   terraform plan
   terraform apply
   ```
   
   This creates:
   - S3 bucket for state storage (with versioning and encryption)
   - DynamoDB table for state locking

2. **Update Backend Configuration**
   
   After the bootstrap step, note the S3 bucket name from the output and update the backend configuration in `terraform/terraform.tf` if needed.

3. **Deploy Main Infrastructure**
   ```bash
   cd ../terraform
   terraform init
   terraform plan
   terraform apply
   ```

### Deployment Commands

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# View current state
terraform show

# Destroy infrastructure (when needed)
terraform destroy
```

## 🔧 Configuration

### Region and Availability Zones
- **Primary Region**: `eu-west-2` (London)
- **Availability Zones**: a, b, c (for high availability)

### Customization Options

You can customize the deployment by modifying variables in `locals.tf`:

- **Subnet CIDR blocks**: Adjust the IP ranges for your network requirements
- **Instance types**: Change node group instance types in `eks.tf`
- **Scaling configuration**: Modify min/max/desired node counts
- **EKS version**: Update the Kubernetes version as needed

## 🔒 Security Considerations

### Current Setup (Example/Showcase)
- EKS endpoint has public access enabled
- Default security groups are used
- Single NAT gateway for cost optimization

### Production Recommendations
- Implement custom security groups with minimal required permissions
- Use private EKS endpoint with bastion host or VPN access
- Deploy NAT gateways in each AZ for high availability
- Enable VPC Flow Logs for network monitoring
- Implement network ACLs for additional security layers
- Use AWS Systems Manager Session Manager instead of SSH

## 🔄 State Management

This infrastructure uses Terraform remote state with:
- **S3 Backend**: Encrypted state storage with versioning
- **DynamoDB Locking**: Prevents concurrent state modifications
