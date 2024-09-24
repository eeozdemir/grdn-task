# Project Architecture and General Structure

## 1. Overview

This project implements a microservice-based application deployment on AWS using Kubernetes. The project utilizes Terraform for infrastructure management, Kubernetes for application deployment, and ArgoCD for GitOps workflow.

## 2. Main Components

### 2.1 Network Infrastructure (VPC)

- **Structure**: Public and private subnets within a VPC
- **Purpose**: Provide an isolated and secure network environment
- **Components**:
  - Public subnets: For Load Balancer
  - Private subnets: For EKS nodes and RDS
  - NAT Gateway: For internet access from private subnets
  - Internet Gateway: For internet connectivity to public subnets

### 2.2 Kubernetes Cluster (EKS)

- **Structure**: Kubernetes cluster running on AWS EKS
- **Purpose**: Orchestrate containerized applications
- **Components**:
  - EKS Control Plane
  - Worker Nodes (EC2 instances)
  - Kubernetes services and deployments

### 2.3 Database (RDS)

- **Structure**: PostgreSQL database on AWS RDS
- **Purpose**: Store and manage application data
- **Features**:
  - High availability with Multi-AZ deployment
  - Automated backups and maintenance

### 2.4 Secrets Management

- **Structure**: AWS Secrets Manager
- **Purpose**: Securely store and manage sensitive information (e.g., DB credentials)

### 2.5 CI/CD and GitOps (ArgoCD)

- **Structure**: ArgoCD running within the Kubernetes cluster
- **Purpose**: Automatically apply changes from Git repository to the cluster
- **Workflow**:
  1. Developer updates code and pushes to Git
  2. ArgoCD detects changes
  3. ArgoCD synchronizes the Kubernetes cluster with the state in the Git repo

### 2.6 Monitoring and Logging

- **Structure**: AWS CloudWatch
- **Purpose**: Collect application and infrastructure metrics, analyze logs
- **Components**:
  - CloudWatch Logs: For log management
  - CloudWatch Metrics: For monitoring performance metrics
  - CloudWatch Alarms: For detecting and alerting critical conditions

## 3. Data Flow

1. User requests come through AWS Application Load Balancer
2. Load Balancer routes requests to appropriate Kubernetes services
3. Kubernetes services distribute traffic to relevant pods
4. Pods access the RDS database when necessary
5. Logs are sent to CloudWatch throughout all operations
6. Metrics are collected and analyzed by CloudWatch

## 4. Security Structure

- VPC provides network isolation with public and private subnets
- Security Groups act as a firewall for EC2 instances and RDS
- IAM roles are configured with the principle of least privilege
- All sensitive information is stored encrypted in AWS Secrets Manager
- Kubernetes RBAC is used for in-cluster access control

## 5. Scaling Strategy

- **Horizontal Scaling**: Kubernetes Horizontal Pod Autoscaler (HPA) automatically increases and decreases the number of pods
- **Vertical Scaling**: AWS Auto Scaling Group is used for EKS nodes
- **Database Scaling**: RDS instance type can be manually changed when needed

## 6. Disaster Recovery and High Availability

- EKS cluster operates across multiple Availability Zones
- RDS is configured with Multi-AZ deployment
- Regular backups are taken with RDS and EBS snapshots
- ArgoCD enables quick recovery from Git repository

## 7. Development and Deployment Process

1. Developers write code in local environment
2. Code is committed to feature branches
3. Pull Request is opened and code review is conducted
4. Approved PRs are merged to the main branch
5. ArgoCD detects changes in the main branch and automatically applies them to the cluster

This architectural structure provides a scalable, secure, and highly available application infrastructure. GitOps principles with continuous deployment and infrastructure-as-code approach facilitate the management and maintenance of the project.
