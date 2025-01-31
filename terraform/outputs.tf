output "eks_cluster_name" {
  value       = aws_eks_cluster.eks_cluster.name
  description = "Nombre del clúster EKS"
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.eks_cluster.endpoint
  description = "Endpoint del clúster EKS"
}

output "eks_cluster_arn" {
  value       = aws_eks_cluster.eks_cluster.arn
  description = "ARN del clúster EKS"
}

output "eks_node_group_name" {
  value       = aws_eks_node_group.eks_node_group.node_group_name
  description = "Nombre del grupo de nodos EKS"
}
