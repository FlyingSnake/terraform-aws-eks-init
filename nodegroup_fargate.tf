resource "aws_eks_fargate_profile" "eks_fargate_profile" {
  for_each               = { for idx, ng in var.eks_fargate_nodegroups : idx => ng }
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "${var.name_prefix}${each.value.profile_name}"
  pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn
  subnet_ids             = each.value.subnet_ids

  selector {
    namespace = each.value.namespace
    labels    = each.value.node_labels
  }


  tags = merge({ Name = "${var.name_prefix}${each.value.profile_name}" }, var.tags)
}

resource "aws_iam_role" "eks_fargate_role" {
  name = "${var.name_prefix}role-eks-node-fargate"
  tags = merge({ Name = "${var.name_prefix}role-eks-node-fargate" }, var.tags)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_role_attch_AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_role.name
}
