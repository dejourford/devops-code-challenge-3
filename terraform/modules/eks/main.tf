# EKS Cluster
resource "aws_eks_cluster" "this" {
  name = "${var.project}-${var.environment}-eks-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = var.cluster_role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

}
