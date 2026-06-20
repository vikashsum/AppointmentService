output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.app.name
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
