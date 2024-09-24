# EKS-Based Microservices Project

## Overview

This project implements a scalable, microservices-based application deployment on AWS using Kubernetes (EKS). It utilizes Terraform for infrastructure management, Kubernetes for application deployment, and ArgoCD for GitOps workflow.

## Repository Structure

The folder structure of this project consists of three main folders. These folders are: kubernetes microservices and terraform. Kubernetes folder contains kubernetes manifest files. Microservices folder contains two microservice folders, backend and frontend, and terraform files. These two microservice folders contain the main files that will create the relevant microservice. Another folder in the main directory is the terraform folder. This folder contains various .tf files that will allow us to create the entire infrastructure.

## Install prerequests

- AWS CLI
- Terraform
- kubectl
- ArgoCD
- Nodejs
- Docker

## Configure AWS CLI

You must define user information with the `aws configure` command.

## Initialize and apply Terraform

`
cd terraform
terraform init
terraform plan
terraform apply
`

## Configure kubectl

aws eks get-token --cluster-name your-cluster-name | kubectl apply -f -

## Install ArgoCD

kubectl create namespace argocd
kubectl apply -n argocd -f <https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml>

## Deploy applications using ArgoCD

kubectl apply -f kubernetes/argocd/applications.yaml

## Contributing to GitOps Workflow

1. Fork the repository.
2. Create a new branch for your feature: `git checkout -b feature/your-feature-name`
3. Make changes to the Kubernetes manifests in the `kubernetes/` directory.
4. Commit your changes: `git commit -am 'Add some feature'`
5. Push to the branch: `git push origin feature/your-feature-name`
6. Submit a pull request.

ArgoCD will automatically detect changes in the main branch and apply them to the cluster.

## Important Commands

- Get EKS cluster info:

  aws eks describe-cluster --name your-cluster-name

- List all pods:

  kubectl get pods --all-namespaces

- Get ArgoCD admin password:

  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

- Port forward ArgoCD UI:

  kubectl port-forward svc/argocd-server -n argocd 8080:443

## Troubleshooting Guide

### Common Issues

1. **Pods in CrashLoopBackOff state**

- Check pod logs: `kubectl logs <pod-name> -n <namespace>`
- Ensure resource limits are set correctly
- Verify environment variables and config maps

2. **ArgoCD sync failures**

- Check ArgoCD app status: `kubectl describe application <app-name> -n argocd`
- Verify Git repository accessibility
- Ensure Kubernetes manifests are valid

3. **EKS cluster unreachable**

- Verify AWS CLI configuration
- Check VPC and security group settings
- Ensure IAM roles and policies are correctly set up

### Logging and Monitoring

- Access CloudWatch logs for EKS:

aws logs get-log-events --log-group-name /aws/eks/your-cluster-name/cluster --log-stream-name kube-apiserver-audit-your-cluster-id

- View cluster metrics in CloudWatch dashboard:

1. Open AWS Console
2. Navigate to CloudWatch
3. Select 'Dashboards' and choose your EKS dashboard

For more detailed troubleshooting, refer to `docs/troubleshooting.md`.

## Additional Resources

- [Project Architecture](architecture.md)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [ArgoCD User Guide](https://argo-cd.readthedocs.io/en/stable/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
