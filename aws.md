# AWS Services and EKS Setup

## Overview

This project implements a microservice-based application deployment on AWS using Kubernetes. The project utilizes Terraform for infrastructure management, Kubernetes for application deployment, and ArgoCD for GitOps workflow.

## Network Infrastructure (VPC)

A VPC is created with both public and private subnets to provide an isolated and secure network environment.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "production"
  }
}


## Network Infrastructure (VPC)

An EKS cluster is deployed to orchestrate our containerized applications.

`module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "main-cluster"
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  node_groups = {
    example = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.medium"
    }
  }
}`


## Kubernetes Cluster (EKS)

An EKS cluster is deployed to orchestrate our containerized applications.

`module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "main-cluster"
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  node_groups = {
    example = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.medium"
    }
  }
}`

## Database (RDS)

An RDS instance is used for database storage.

`resource "aws_db_instance" "main" {
  identifier        = "main-db"
  engine            = "postgres"
  engine_version    = "13.7"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"
  
  db_name  = "myapp"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = {
    Environment = "production"
  }
}`

## Secrets Management

AWS Secrets Manager is used to securely manage sensitive information like database credentials.

`resource "aws_secretsmanager_secret" "db_credentials" {
  name = "db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}`


## Monitoring and Logging (CloudWatch)

CloudWatch is used to monitor our infrastructure and applications.

`resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
}`


# EKS Setup and Configuration

## IAM Roles and Policies

IAM roles and policies are set up to allow EKS to manage resources.

`resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}`


## Security Groups

Security groups are configured to control network access to the EKS cluster.

`resource "aws_security_group" "eks_cluster" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}`


## EKS Add-ons

We've enabled several EKS add-ons to enhance cluster functionality.

`resource "aws_eks_addon" "vpc_cni" {
  cluster_name = module.eks.cluster_id
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_id
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = module.eks.cluster_id
  addon_name   = "kube-proxy"
}`


## Post-Setup Configuration

After setting up the EKS cluster, we apply Kubernetes manifests and configure access.

`
aws eks get-token --cluster-name main-cluster | kubectl apply -f -

kubectl apply -f kubernetes/
`


Applications are deployed using ArgoCD, which watches our Git repository for changes and applies them to the cluster automatically. CloudWatch is used to monitor the EKS cluster and applications, with logs and metrics automatically sent to CloudWatch. This setup provides a robust, scalable, and secure environment for running our Kubernetes applications on AWS.
