output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.app.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.app.arn
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.app.endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster CA certificate"
  value       = aws_eks_cluster.app.certificate_authority[0].data
}

output "node_group_name" {
  description = "EKS worker node group name"
  value       = aws_eks_node_group.app_nodes.node_group_name
}

output "node_group_role_arn" {
  description = "EKS worker node IAM role ARN"
  value       = aws_iam_role.worker_node.arn
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_security_group.eks_cluster.id
}
