provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
}

module "microservices" {
  source = "./modules/microservice/frontend"
  
  cluster_name     = module.eks.cluster_name
  frontend_image   = var.frontend_image
}

module "microservices" {
  source = "./modules/microservices/backend"
  
  cluster_name     = module.eks.cluster_name
  backend_image    = var.backend_image
}