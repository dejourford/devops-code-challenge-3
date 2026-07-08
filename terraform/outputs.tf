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

output "lb_controller_role_arn" {
  value = module.iam.lb_controller_role_arn
}

output "jenkins_instance_id" {
  value = module.jenkins.jenkins_instance_id
}

output "jenkins_public_ip" {
  value = module.jenkins.jenkins_public_ip
}
