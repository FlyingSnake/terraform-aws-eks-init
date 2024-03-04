resource "aws_instance" "ec2_bastion_server" {
  count                  = var.ec2_bastion_server.enabled ? 1 : 0
  tags                   = merge({ Name = "${var.name_prefix}${coalesce(var.ec2_bastion_server.name, "bastion-server")}" }, var.tags)
  ami                    = coalesce(var.ec2_bastion_server.ami, "ami-051f7e7f6c2f40dc1")
  instance_type          = coalesce(var.ec2_bastion_server.instance_type, "t2.micro")
  subnet_id              = var.ec2_bastion_server.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ec2_bastion_server_profile[0].name
  vpc_security_group_ids = concat([aws_security_group.ec2_bastion_server_sg[0].id], coalesce(var.ec2_bastion_server.additional_security_group_ids, []))
  key_name = (var.ec2_bastion_server.ssh_config.enabled
    ? var.ec2_bastion_server.ssh_config.new
    ? aws_key_pair.ec2_bastion_key_pair[0].key_name
    : var.ec2_bastion_server.ssh_config.key_name
  : null)
  user_data  = <<-EOF
    #!/bin/bash
    sudo su
    yum update -y
    cd ~
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/${lookup(local.ec2_bastion_kubectl_download_eks_version_map, var.eks_cluster.version)}/${lookup(local.ec2_bastion_kubectl_download_eks_version_date_map, var.eks_cluster.version)}/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
    echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
    aws eks update-kubeconfig --region ${data.aws_region.current.id} --name ${var.name_prefix}${var.eks_cluster.name}
    EOF
  depends_on = [aws_key_pair.ec2_bastion_key_pair]
}

resource "aws_iam_role" "ec2_bastion_server_role" {
  count = var.ec2_bastion_server.enabled ? 1 : 0
  name  = "${var.name_prefix}role-ec2-bastion-server"
  tags  = merge({ Name = "${var.name_prefix}role-ec2-bastion-server" }, var.tags)

  inline_policy {
    name = "list_eks_clusters_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "eks:DescribeCluster"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_bastion_server_role_attach_AmazonSSMManagedInstanceCore" {
  count      = var.ec2_bastion_server.enabled && var.ec2_bastion_server.ssm_agent_enabled == true ? 1 : 0
  role       = aws_iam_role.ec2_bastion_server_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  depends_on = [aws_iam_instance_profile.ec2_bastion_server_profile]
}
resource "aws_iam_instance_profile" "ec2_bastion_server_profile" {
  count = var.ec2_bastion_server.enabled ? 1 : 0
  name  = "${var.name_prefix}profile-ec2-bastion-server"
  role  = aws_iam_role.ec2_bastion_server_role[0].name
}


resource "aws_security_group" "ec2_bastion_server_sg" {
  count  = var.ec2_bastion_server.enabled ? 1 : 0
  vpc_id = var.vpc_id
  name   = "${var.name_prefix}sg-ec2-bastion-server"
  tags   = merge({ Name = "${var.name_prefix}sg-ec2-bastion-server" }, var.tags)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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


resource "tls_private_key" "ec2_bastion_key_alorithm" {
  count     = var.ec2_bastion_server.enabled && var.ec2_bastion_server.ssh_config.new == true ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "ec2_bastion_private_key" {
  count           = var.ec2_bastion_server.enabled && var.ec2_bastion_server.ssh_config.new == true ? 1 : 0
  content         = tls_private_key.ec2_bastion_key_alorithm[0].private_key_pem
  filename        = "${path.module}/key-pair/${var.name_prefix}${local.ec2_bastion_ssh_key_name}.pem"
  file_permission = "0600"
}

resource "local_file" "ec2_bastion_public_key" {
  count    = var.ec2_bastion_server.enabled && var.ec2_bastion_server.ssh_config.new == true ? 1 : 0
  content  = tls_private_key.ec2_bastion_key_alorithm[0].public_key_openssh
  filename = "${path.module}/key-pair/${var.name_prefix}${local.ec2_bastion_ssh_key_name}.pub"
}

resource "aws_key_pair" "ec2_bastion_key_pair" {
  count      = var.ec2_bastion_server.enabled && var.ec2_bastion_server.ssh_config.new == true ? 1 : 0
  key_name   = "${var.ec2_bastion_server.ssh_config.new ? var.name_prefix : ""}${local.ec2_bastion_ssh_key_name}"
  public_key = tls_private_key.ec2_bastion_key_alorithm[0].public_key_openssh
}

