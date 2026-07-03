output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "node_role_name" {
  value = aws_iam_role.eks_nodes.name
}

output "lb_controller_role_arn" {
  value = aws_iam_role.lb_controller.arn
}
