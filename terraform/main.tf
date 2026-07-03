module "vpc" {
  source = "./modules/vpc"
  
  public_a_cidr = var.public_a_cidr
  public_b_cidr = var.public_b_cidr
  private_b_cidr = var.private_b_cidr
  private_a_cidr = var.private_a_cidr
  vpc_cidr = var.vpc_cidr
  project = var.project
  environment = var.environment
}

module "ecr" {
  source = "./modules/ecr"
  
  project = var.project
  environment = var.environment
}

module "iam" {
  source = "./modules/iam"

  project          = var.project
  environment      = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  account_id       = data.aws_caller_identity.current.account_id
}

# Add this data source to root main.tf
data "aws_caller_identity" "current" {}

module "eks" {
  source = "./modules/eks"

  project            = var.project
  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_role_arn   = module.iam.cluster_role_arn
}

module "node_group" {
  source = "./modules/node-group"

  project            = var.project
  environment        = var.environment
  cluster_name       = module.eks.cluster_name
  node_role_arn      = module.iam.node_role_arn
  private_subnet_ids = module.vpc.private_subnet_ids
}
