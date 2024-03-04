resource "aws_eks_node_group" "eks_ec2_nodegroups" {
  for_each        = { for idx, ng in var.eks_ec2_nodegroups : idx => ng }
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.name_prefix}${each.value.name}"
  node_role_arn   = each.value.ssm_agent_enabled ? aws_iam_role.eks_ec2_node_ssm_agent_role.arn : aws_iam_role.eks_ec2_node_role.arn
  subnet_ids      = each.value.subnet_ids
  instance_types  = each.value.instance_type
  capacity_type   = each.value.capacity_type != null ? each.value.capacity_type : "ON_DEMAND"
  labels          = each.value.node_labels
  tags            = merge({ Name = "${var.name_prefix}${each.value.name}" }, var.tags)

  scaling_config {
    desired_size = each.value.instance_number.desired
    max_size     = each.value.instance_number.max
    min_size     = each.value.instance_number.min
  }

  dynamic "taint" {
    for_each = coalesce(each.value.taints, [])
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  dynamic "remote_access" {
    for_each = each.value.ssh_config.enabled ? [1] : []
    content {
      ec2_ssh_key               = (each.value.ssh_config.key_name == null || each.value.ssh_config.key_name == "") ? aws_key_pair.eks_ec2_node_key_pair.key_name : each.value.ssh_config.key_name
      source_security_group_ids = each.value.ssh_config.source_security_group_ids != null ? each.value.ssh_config.source_security_group_ids : []
    }
  }
  depends_on = [aws_iam_role.eks_ec2_node_ssm_agent_role, aws_iam_role.eks_ec2_node_role, aws_key_pair.eks_ec2_node_key_pair]
}


#### IAM config
resource "aws_iam_role" "eks_ec2_node_role" {
  name               = "${var.name_prefix}role-eks-ec2-node"
  tags               = merge({ Name = "${var.name_prefix}role-eks-ec2-node" }, var.tags)
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_role" "eks_ec2_node_ssm_agent_role" {
  name               = "${var.name_prefix}role-eks-ec2-node-ssma"
  tags               = merge({ Name = "${var.name_prefix}role-eks-ec2-node-ssma" }, var.tags)
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#### IAM Attach SSM Agent Disabled
resource "aws_iam_role_policy_attachment" "eks_ec2_node_role_attach_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_ec2_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ec2_node_role_attach_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_ec2_node_role.name
}
resource "aws_iam_role_policy_attachment" "eks_ec2_node_role_attach_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_ec2_node_role.name
}

resource "aws_iam_instance_profile" "eks_ec2_node_profile" {
  name = "${var.name_prefix}eks-node-profile"
  role = aws_iam_role.eks_ec2_node_role.name
  tags = merge({ Name = "${var.name_prefix}eks-node-profile" }, var.tags)
}

#### IAM Attach SSM Agent Enabled
resource "aws_iam_role_policy_attachment" "eks_ec2_node_ssma_role_attach_AmazonSSMManagedInstancre" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_ec2_node_ssm_agent_role.name
}
resource "aws_iam_role_policy_attachment" "eks_ec2_node_ssma_role_attach_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_ec2_node_ssm_agent_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ec2_node_ssma_role_attach_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_ec2_node_ssm_agent_role.name
}
resource "aws_iam_role_policy_attachment" "eks_ec2_node_ssma_role_attach_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_ec2_node_ssm_agent_role.name
}

resource "aws_iam_instance_profile" "eks_ec2_node_ssma_profile" {
  name = "${var.name_prefix}eks-node-ec2-ssma-profile"
  role = aws_iam_role.eks_ec2_node_ssm_agent_role.name
  tags = merge({ Name = "${var.name_prefix}eks-node-ec2-ssma-profile" }, var.tags)
}


#### SSH config
resource "tls_private_key" "eks_ec2_node_key_alorithm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "eks_ec2_node_private_key" {
  content         = tls_private_key.eks_ec2_node_key_alorithm.private_key_pem
  filename        = "${path.module}/key-pair/${var.name_prefix}${var.eks_ec2_node_common_ssh_key_name}.pem"
  file_permission = "0600"
}

resource "local_file" "eks_ec2_node_public_key" {
  content  = tls_private_key.eks_ec2_node_key_alorithm.public_key_openssh
  filename = "${path.module}/key-pair/${var.name_prefix}${var.eks_ec2_node_common_ssh_key_name}.pub"
}

resource "aws_key_pair" "eks_ec2_node_key_pair" {
  key_name   = "${var.name_prefix}${var.eks_ec2_node_common_ssh_key_name}"
  public_key = tls_private_key.eks_ec2_node_key_alorithm.public_key_openssh
  tags       = merge({ Name = "${var.name_prefix}${var.eks_ec2_node_common_ssh_key_name}" }, var.tags)
}

