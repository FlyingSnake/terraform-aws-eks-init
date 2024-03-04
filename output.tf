output "eks_version" {
  value = aws_eks_cluster.eks_cluster.version
}
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}
output "eks_oidc_id" {
  value = aws_iam_openid_connect_provider.eks_oidc_provider.arn
}

output "eks_nodegroup_ec2_list" {
  value = [for index, ng in aws_eks_node_group.eks_ec2_nodegroups : ng.node_group_name]
}

output "eks_nodegroup_fargate_list" {
  value = [for ng in aws_eks_fargate_profile.eks_fargate_profile : ng.fargate_profile_name]
}

output "bastion_ec2_arn" {
  value = var.ec2_bastion_server.enabled ? aws_instance.ec2_bastion_server[0].arn : ""
}

output "bastion_cloud9_arn" {
  value = var.cloud9_bastion_server.enabled ? aws_cloud9_environment_ec2.cloud9_bastion_server[0].arn : ""
}

output "enabled_vpc_endpoint_list" {
  value = var.vpc_endpoint.enabled ? coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default) : []
}
