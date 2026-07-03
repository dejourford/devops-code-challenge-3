output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "frontend_repo_url" {
  value = module.ecr.repository_urls["frontend"]
}

output "backend_repo_url" {
  value = module.ecr.repository_urls["backend"]
}
