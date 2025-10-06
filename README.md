# MicroTodo Infrastructure

This repository contains the complete infrastructure-as-code (IaC) configuration for the MicroTodo application - a cloud-native microservices-based todo application deployed on AWS EKS (Elastic Kubernetes Service).

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Infrastructure Components](#infrastructure-components)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Deployment Guide](#deployment-guide)
- [Services](#services)
- [Security](#security)
- [Monitoring and Logging](#monitoring-and-logging)
- [Development](#development)
- [Production Considerations](#production-considerations)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture Overview

MicroTodo is built using a microservices architecture with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │  AWS ALB/NLB   │
                    │   (Ingress)    │
                    └───────┬────────┘
                            │
                    ┌───────▼────────┐
                    │  API Gateway   │
                    └───────┬────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼─────┐      ┌─────▼──────┐     ┌─────▼──────┐
   │  Users   │      │   Tasks    │     │Notifications│
   │ Service  │      │  Service   │     │  Service    │
   └────┬─────┘      └─────┬──────┘     └─────┬──────┘
        │                  │                   │
   ┌────▼─────┐      ┌─────▼──────┐     ┌─────▼──────┐
   │PostgreSQL│      │PostgreSQL  │     │PostgreSQL  │
   │  Users   │      │   Tasks    │     │Notifications│
   └──────────┘      └────────────┘     └────────────┘
                            │
                    ┌───────▼────────┐
                    │   RabbitMQ     │
                    │ (Message Bus)  │
                    └────────────────┘
```

### Key Features

- **Microservices Architecture**: Separate services for users, tasks, and notifications
- **API Gateway Pattern**: Single entry point for all client requests
- **Event-Driven Communication**: RabbitMQ for asynchronous messaging between services
- **Database per Service**: Each microservice has its own PostgreSQL database
- **Container Orchestration**: Kubernetes (EKS) for container management
- **GitOps Deployment**: ArgoCD for continuous deployment
- **Infrastructure as Code**: Terraform for AWS resource provisioning
- **Secrets Management**: AWS Secrets Manager with External Secrets Operator

## 🛠️ Technology Stack

### Infrastructure

- **Cloud Provider**: AWS
- **Kubernetes**: Amazon EKS 1.31
- **Infrastructure as Code**: Terraform (~> 1.13)
- **Container Registry**: Amazon ECR
- **Secret Management**: AWS Secrets Manager
- **State Management**: S3 + DynamoDB for Terraform state

### Kubernetes Ecosystem

- **Ingress Controller**: AWS Load Balancer Controller (v1.13.4)
- **GitOps**: ArgoCD (v8.5.7)
- **Secrets**: External Secrets Operator (v0.20.1)
- **Storage**: AWS EBS CSI Driver
- **Message Queue**: RabbitMQ

### Networking

- **VPC**: Custom VPC with public and private subnets across 3 AZs
- **Load Balancing**: Application Load Balancer (ALB)
- **DNS**: Kubernetes DNS (CoreDNS)
- **Service Mesh**: (Optional - can be added)

## 📦 Infrastructure Components

### AWS Resources

1. **VPC & Networking**
   - Custom VPC (10.0.0.0/16)
   - 3 Public subnets across availability zones
   - 3 Private subnets across availability zones
   - Internet Gateway for public subnet access
   - NAT Gateway for private subnet internet access
   - Route tables for public and private subnets

2. **EKS Cluster**
   - Kubernetes version: 1.31
   - Node group with t3.small instances (2-5 nodes)
   - Managed node groups in private subnets
   - Public and private API endpoints
   - CloudWatch logging enabled

3. **ECR Repositories**
   - `microtodo/api-gateway`
   - `microtodo/users-service`
   - `microtodo/tasks-service`
   - `microtodo/notifications-service`
   - Lifecycle policies (7-day untagged image expiration, keep last 30 tagged images)

4. **IAM Roles & Policies**
   - EKS cluster role
   - EKS node group role
   - AWS Load Balancer Controller role
   - External Secrets Operator role
   - EBS CSI Driver role

5. **Secrets Management**
   - AWS Secrets Manager for sensitive data
   - PostgreSQL credentials
   - RabbitMQ credentials
   - JWT secrets

### Kubernetes Resources

1. **Namespaces**
   - `microtodo`: Main application namespace
   - `argocd`: GitOps controller
   - `external-secrets-system`: Secrets management
   - `kube-system`: System components

2. **Services**
   - API Gateway (entry point)
   - Users Service (authentication & user management)
   - Tasks Service (task management)
   - Notifications Service (notifications)

3. **Databases**
   - PostgreSQL for Users (with persistent storage)
   - PostgreSQL for Tasks (with persistent storage)
   - PostgreSQL for Notifications (with persistent storage)
   - RabbitMQ (message broker)

4. **Ingress**
   - ALB-based ingress for API Gateway
   - HTTP/HTTPS support
   - (Optional) SSL/TLS termination

## ✅ Prerequisites

Before you begin, ensure you have the following installed:

- [AWS CLI](https://aws.amazon.com/cli/) (v2.x)
- [Terraform](https://www.terraform.io/downloads.html) (>= 1.13)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (>= 1.31)
- [Docker](https://docs.docker.com/get-docker/) (for local development)
- [Docker Compose](https://docs.docker.com/compose/install/) (for local development)
- [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) (optional, for ArgoCD management)

### AWS Account Setup

1. AWS account with appropriate permissions
2. AWS CLI configured with credentials:
   ```bash
   aws configure
   ```
3. Note your AWS Account ID (you'll need this for Terraform)

## 🚀 Getting Started

### Step 1: Bootstrap Terraform State Management

First, create the S3 bucket and DynamoDB table for Terraform state:

```bash
cd terraform-bootstrap
terraform init
terraform apply
```

**Important**: Note the outputs from this step:
- `terraform_state_bucket`: Use this in `terraform/terraform.tf` backend configuration
- `terraform_lock_table_name`: Use this in `terraform/terraform.tf` backend configuration

### Step 2: Configure Terraform Variables

Create a `terraform.tfvars` file in the `terraform/` directory:

```hcl
aws_account_id = "your-aws-account-id"

# Database credentials
postgres_username = "postgres"
postgres_password = "your-secure-password"

# RabbitMQ credentials
rabbitmq_username = "rabbit"
rabbitmq_password = "your-secure-password"

# JWT secret
jwt_secret = "your-jwt-secret-key"
```

**Security Note**: Never commit `terraform.tfvars` to version control. It's already in `.gitignore`.

### Step 3: Update Backend Configuration

Update the backend configuration in `terraform/terraform.tf` with the bucket name from Step 1:

```hcl
backend "s3" {
  bucket         = "microtodo-tf-state-XXXXXX"  # From bootstrap output
  key            = "microtodo/terraform.tfstate"
  region         = "eu-west-2"
  dynamodb_table = "microtodo-tf-state-lock"
  encrypt        = true
}
```

### Step 4: Deploy AWS Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This will create:
- VPC and networking components
- EKS cluster and node groups
- ECR repositories
- IAM roles and policies
- Secrets in AWS Secrets Manager
- Install Helm charts (ALB Controller, ArgoCD, External Secrets)

**Note**: This process takes approximately 15-20 minutes.

### Step 5: Configure kubectl

After the EKS cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --region eu-west-2 --name microtodo_eks_cluster
```

Verify the connection:

```bash
kubectl get nodes
kubectl get namespaces
```

### Step 6: Deploy Application Resources

Apply the Kubernetes manifests:

```bash
# Create namespace
kubectl apply -f k8s/namespaces/

# Deploy all resources
kubectl apply -f k8s/
```

### Step 7 (Optional): Configure ArgoCD (GitOps)

1. Get the ArgoCD admin password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
   ```

2. Port-forward to access ArgoCD UI:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

3. Access ArgoCD at `https://localhost:8080`
   - Username: `admin`
   - Password: (from step 1)

### Step 8: Access the Application

Get the Load Balancer URL:

```bash
kubectl get ingress -n microtodo api-gateway-ingress
```

The application will be available at the `ADDRESS` shown in the output.

## 📁 Project Structure

```
infrastructure/
├── docker-compose.dev.yml          # Local development environment
├── scripts/
│   └── download-alb-policy.sh      # Helper script for ALB policy
├── terraform-bootstrap/            # Terraform state backend setup
│   └── main.tf                     # S3 bucket and DynamoDB table
├── terraform/                      # Main infrastructure code
│   ├── main.tf                     # AWS provider configuration
│   ├── terraform.tf                # Terraform and backend configuration
│   ├── variables.tf                # Input variables
│   ├── locals.tf                   # Local values
│   ├── vpc.tf                      # VPC and networking
│   ├── eks.tf                      # EKS cluster and node groups
│   ├── ecr.tf                      # Container registries
│   ├── iam.tf                      # IAM roles and policies
│   ├── secrets.tf                  # AWS Secrets Manager
│   ├── helm-charts.tf              # Helm releases (ALB, ArgoCD, External Secrets)
│   └── iam-policies/
│       └── aws-load-balancer-controller-policy.json
└── k8s/                            # Kubernetes manifests
    ├── namespaces/
    │   └── microtodo.yaml          # Application namespace
    ├── storage/
    │   └── gp3-storageclass.yaml   # EBS GP3 storage class
    ├── external-secrets/
    │   ├── secret-store.yaml       # AWS Secrets Manager integration
    │   └── external-secret.yaml    # Secret definitions
    ├── databases/
    │   ├── postgres-users.yaml     # Users database
    │   ├── postgres-tasks.yaml     # Tasks database
    │   ├── postgres-notifications.yaml  # Notifications database
    │   └── rabbitmq.yaml           # Message broker
    ├── services/
    │   ├── api-gateway/
    │   │   ├── deployment.yaml
    │   │   ├── service.yaml
    │   │   └── configmap.yaml
    │   ├── users-service/
    │   │   ├── deployment.yaml
    │   │   ├── service.yaml
    │   │   ├── configmap.yaml
    │   │   └── migrate.yaml        # Database migration job
    │   ├── tasks-service/
    │   │   ├── deployment.yaml
    │   │   ├── service.yaml
    │   │   ├── configmap.yaml
    │   │   └── migrate.yaml
    │   └── notifications-service/
    │       ├── deployment.yaml
    │       ├── service.yaml
    │       ├── configmap.yaml
    │       └── migrate.yaml
    ├── ingress/
    │   └── api-gateway-ingress.yaml  # ALB ingress
    └── argocd/
        └── application.yaml          # ArgoCD application definition
```

## 📖 Deployment Guide

### Manual Deployment

Follow the steps in [Getting Started](#getting-started) for initial deployment.

### GitOps Deployment with ArgoCD

Once ArgoCD is configured:

1. Any changes pushed to the `master` branch in the `k8s/` directory will be automatically detected by ArgoCD
2. ArgoCD will sync the changes to the cluster based on the sync policy (automated with pruning and self-healing)
3. Monitor deployments in the ArgoCD UI

### CI/CD Pipeline (Recommended for Production)

A typical CI/CD workflow:

1. **Build Phase**:
   - Build Docker images for each service
   - Tag images with commit SHA or version
   - Push to ECR repositories

2. **Update Manifests**:
   - Update image tags in Kubernetes deployments
   - Commit changes to infrastructure repository

3. **ArgoCD Sync**:
   - ArgoCD detects changes
   - Applies updates to the cluster
   - Verifies deployment health

Example GitHub Actions workflow (pseudo-code):

```yaml
name: Deploy Service
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Build and push Docker image
        # Build image and push to ECR
      
      - name: Update Kubernetes manifests
        # Update image tags in infrastructure repo
      
      - name: Wait for ArgoCD sync
        # Monitor ArgoCD for successful deployment
```

## 🔧 Services

### API Gateway

- **Purpose**: Single entry point for all client requests, handles routing to microservices
- **Port**: 80 (internal), exposed via ALB
- **Health Checks**: TCP-based health probes
- **Scaling**: 2 replicas (configurable)

### Users Service

- **Purpose**: User authentication, registration, and profile management
- **Port**: 3000
- **Database**: PostgreSQL (postgres-users)
- **Features**:
  - JWT-based authentication
  - User CRUD operations
  - Password hashing and validation
- **Health Checks**: TCP-based startup, liveness, and readiness probes

### Tasks Service

- **Purpose**: Task management (create, read, update, delete tasks)
- **Port**: 3001
- **Database**: PostgreSQL (postgres-tasks)
- **Message Queue**: RabbitMQ (publishes task events)
- **Features**:
  - Task CRUD operations
  - Task assignment and status tracking
  - Event publishing for notifications

### Notifications Service

- **Purpose**: Handle notifications triggered by task events
- **Port**: 3002
- **Database**: PostgreSQL (postgres-notifications)
- **Message Queue**: RabbitMQ (consumes task events)
- **Features**:
  - Notification creation and delivery
  - Event-driven architecture
  - Notification history

## 🔒 Security

### Network Security

- **VPC Isolation**: Services run in private subnets
- **Security Groups**: (Should be implemented for production)
- **NAT Gateway**: Controlled internet access for private subnets
- **ALB**: Public-facing load balancer with optional SSL/TLS

### Secrets Management

- **AWS Secrets Manager**: Centralized secret storage
- **External Secrets Operator**: Syncs secrets to Kubernetes
- **IRSA (IAM Roles for Service Accounts)**: Fine-grained AWS permissions
- **Environment Variables**: Secrets injected as env vars, never in code

### Authentication & Authorization

- **JWT**: Token-based authentication
- **Service-to-Service**: Internal communication (consider mTLS for production)

### Best Practices Implemented

✅ Secrets stored in AWS Secrets Manager, not in code  
✅ Terraform state encrypted and stored remotely  
✅ ECR image scanning (commented out for cost reasons)  
✅ Database credentials rotated through AWS Secrets Manager  
✅ Principle of least privilege for IAM roles  
✅ Private subnets for workloads  

### Production Security Enhancements (TODO)

⚠️ Implement Network Policies for pod-to-pod communication  
⚠️ Add Web Application Firewall (WAF) to ALB  
⚠️ Enable SSL/TLS with AWS Certificate Manager  
⚠️ Implement Security Groups for EKS  
⚠️ Enable VPC Flow Logs  
⚠️ Add Pod Security Standards/Policies  
⚠️ Implement secret rotation  
⚠️ Add vulnerability scanning for container images (ECR) 

## 📊 Monitoring and Logging

### Current Setup

- **EKS Control Plane Logs**: Enabled for API, audit, authenticator, controller manager, and scheduler
- **kubectl logs**: View container logs

```bash
# View service logs
kubectl logs -f deployment/users-service -n microtodo
kubectl logs -f deployment/tasks-service -n microtodo
kubectl logs -f deployment/notifications-service -n microtodo

# View pod events
kubectl describe pod <pod-name> -n microtodo
```

### Recommended Additions for Production

1. **Metrics Collection**:
   - Prometheus for metrics scraping
   - Grafana for visualization
   - Custom dashboards for business metrics

2. **Distributed Tracing**:
   - Jaeger or AWS X-Ray
   - Trace requests across microservices

3. **Log Aggregation**:
   - ELK Stack (Elasticsearch, Logstash, Kibana)
   - Fluentd or Fluent Bit for log collection
   - CloudWatch Logs Insights

4. **Alerting**:
   - Alertmanager (with Prometheus)
   - PagerDuty integration
   - Slack notifications

## 💻 Development

### Local Development with Docker Compose

For local development, use the provided Docker Compose file:

```bash
docker-compose -f docker-compose.dev.yml up -d
```

This starts:
- RabbitMQ with management UI (ports 5672, 15672)

Access RabbitMQ Management UI:
- URL: http://localhost:15672
- Default credentials: guest/guest

### Testing Kubernetes Manifests

Validate Kubernetes manifests before applying:

```bash
# Dry-run
kubectl apply -f k8s/ --dry-run=client

# Validate with kubeval (if installed)
kubeval k8s/**/*.yaml

### Terraform Development

```bash
cd terraform

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Updating Service Images

1. Build and push new image to ECR:
   ```bash
   # Authenticate to ECR
   aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-west-2.amazonaws.com
   
   # Build and push
   docker build -t microtodo/users-service:v1.2.3 .
   docker tag microtodo/users-service:v1.2.3 <account-id>.dkr.ecr.eu-west-2.amazonaws.com/microtodo/users-service:v1.2.3
   docker push <account-id>.dkr.ecr.eu-west-2.amazonaws.com/microtodo/users-service:v1.2.3
   ```

2. Update the deployment manifest:
   ```yaml
   spec:
     containers:
       - name: users-service
         image: <account-id>.dkr.ecr.eu-west-2.amazonaws.com/microtodo/users-service:v1.2.3
   ```

3. Commit and push (ArgoCD will auto-sync if configured)

## 🏭 Production Considerations

### High Availability

- [ ] **Multi-AZ NAT Gateways**: Currently using single NAT Gateway (cost optimization). For production, deploy NAT Gateway per AZ.
- [ ] **Database High Availability**: Consider Amazon RDS for PostgreSQL with Multi-AZ deployment
- [ ] **RabbitMQ Cluster**: Deploy RabbitMQ in cluster mode for HA
- [ ] **Pod Disruption Budgets**: Ensure minimum replicas during voluntary disruptions
- [ ] **HPA (Horizontal Pod Autoscaler)**: Auto-scale based on CPU/memory/custom metrics

### Performance Optimization

- [ ] **CDN**: CloudFront for static assets
- [ ] **Caching**: Redis/Memcached for frequently accessed data
- [ ] **Database Indexing**: Optimize database queries with proper indexes
- [ ] **Connection Pooling**: Implement efficient database connection pooling
- [ ] **Resource Limits**: Fine-tune CPU/memory requests and limits

### Cost Optimization

Current cost-saving measures:
- Single NAT Gateway (vs. 3 per AZ)
- Smaller EC2 instance types (t3.small)
- ECR image scanning disabled
- Public EKS endpoint (vs. private only with VPN)

Production cost considerations:
- [ ] Use Reserved Instances or Savings Plans for predictable workloads
- [ ] Right-size EC2 instances based on actual usage
- [ ] Enable cluster autoscaler
- [ ] Set up cost alerts and budgets in AWS
- [ ] Review and optimize EBS volume sizes

### Disaster Recovery

- [ ] **Backup Strategy**: Regular backups of databases and persistent volumes
- [ ] **Cross-Region Replication**: Replicate critical data to another region
- [ ] **Disaster Recovery Plan**: Document and test DR procedures
- [ ] **RTO/RPO**: Define Recovery Time Objective and Recovery Point Objective

### Security Hardening

- [ ] **TLS/SSL**: Enable HTTPS with valid certificates
- [ ] **Network Policies**: Restrict pod-to-pod communication
- [ ] **Pod Security Standards**: Enforce security contexts
- [ ] **Image Scanning**: Enable ECR vulnerability scanning
- [ ] **Audit Logging**: Comprehensive audit trail
- [ ] **WAF**: Web Application Firewall for ALB
- [ ] **Penetration Testing**: Regular security assessments

### Compliance

- [ ] **Data Encryption**: At-rest and in-transit encryption
- [ ] **GDPR Compliance**: Data privacy and user rights
- [ ] **Access Logs**: Maintain comprehensive access logs
- [ ] **Regular Audits**: Compliance and security audits

## 🐛 Troubleshooting

### Common Issues

#### 1. Terraform State Lock

**Problem**: `Error acquiring the state lock`

**Solution**:
```bash
# Release the lock (use with caution!)
terraform force-unlock <lock-id>
```

#### 2. EKS Cluster Access Denied

**Problem**: `error: You must be logged in to the server (Unauthorized)`

**Solution**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-2 --name microtodo_eks_cluster

# Verify AWS CLI credentials
aws sts get-caller-identity
```

#### 3. Pod Not Starting

**Problem**: Pods stuck in `Pending`, `CrashLoopBackOff`, or `ImagePullBackOff`

**Solution**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n microtodo

# Check logs
kubectl logs <pod-name> -n microtodo

# Common fixes:
# - Verify ECR authentication
# - Check resource requests/limits
# - Verify secrets are populated
kubectl get secrets -n microtodo
kubectl describe externalsecret microtodo-secrets -n microtodo
```

#### 4. Database Connection Issues

**Problem**: Services can't connect to databases

**Solution**:
```bash
# Verify database pods are running
kubectl get pods -n microtodo | grep postgres

# Check database service
kubectl get svc -n microtodo | grep postgres

# Verify secrets
kubectl get secret microtodo-secrets -n microtodo -o yaml

# Test connection from a debug pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n microtodo -- psql -h postgres-users-service -U postgres
```

#### 5. ArgoCD Out of Sync

**Problem**: ArgoCD shows application as `OutOfSync`

**Solution**:
```bash
# Manual sync via CLI
argocd app sync microtodo-app

# Or via kubectl
kubectl -n argocd patch app microtodo-app -p '{"operation":{"sync":{}}}' --type merge

# Check sync status
argocd app get microtodo-app
```

#### 6. Load Balancer Not Created

**Problem**: Ingress doesn't provision ALB

**Solution**:
```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify ingress class
kubectl get ingressclass

# Check IAM permissions for ALB controller
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
```

### Useful Commands

```bash
# Check cluster health
kubectl get nodes
kubectl get componentstatuses

# View all resources in microtodo namespace
kubectl get all -n microtodo

# Check resource usage
kubectl top nodes
kubectl top pods -n microtodo

# View events
kubectl get events -n microtodo --sort-by='.lastTimestamp'

# Port forward to a service
kubectl port-forward svc/<service-name> -n microtodo <local-port>:<service-port>

# Execute command in pod
kubectl exec -it <pod-name> -n microtodo -- /bin/sh

# View Terraform state
cd terraform
terraform state list
terraform state show <resource>

# ArgoCD password recovery
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 📚 Additional Resources

### Documentation

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [External Secrets Operator](https://external-secrets.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

### Tutorials

- [EKS Workshop](https://www.eksworkshop.com/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [GitOps with ArgoCD](https://argoproj.github.io/argo-cd/getting_started/)

---

**Note**: This infrastructure is set up for learning and development purposes. For production deployments, review and implement the security hardening, high availability, and monitoring recommendations outlined in this document.

