resource "aws_eks_cluster" "eks_cluster" {
  name                      = "${var.name_prefix}${var.eks_cluster.name}"
  role_arn                  = aws_iam_role.eks_cluster_role.arn
  version                   = var.eks_cluster.version
  enabled_cluster_log_types = [for k, v in var.eks_cluster.logging_options : k if v == true]
  tags                      = merge({ Name = "${var.name_prefix}${var.eks_cluster.name}" }, var.tags)


  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    subnet_ids              = var.eks_cluster.subnet_ids
    endpoint_private_access = var.eks_cluster.endpoint_access.private
    endpoint_public_access  = var.eks_cluster.endpoint_access.public
    public_access_cidrs     = toset([coalesce(var.eks_cluster.endpoint_access.public_access_cidr, "0.0.0.0/0")])
  }
  depends_on = [aws_iam_role.eks_cluster_role]
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.name_prefix}role_eks_cluster"
  tags = merge({ Name = "${var.name_prefix}role_eks_cluster" }, var.tags)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        "Service" : "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_attach_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_attach_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}


data "tls_certificate" "eks_tls" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}


data "aws_iam_policy_document" "eks_oidc_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_security_group" "eks_cluster_sg" {
  vpc_id = var.vpc_id
  name   = "${var.name_prefix}sg-eks-cluster"
  tags   = merge({ Name = "${var.name_prefix}sg-eks-cluster" }, var.tags)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
    description = "Allow Self"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    description = "Allow pods to communicate with each other node"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
