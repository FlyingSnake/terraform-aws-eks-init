data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpc" "vpc" {
  id = var.vpc_id
}
# bastion server download config
locals {
  ec2_bastion_ssh_key_name = coalesce(var.ec2_bastion_server.ssh_config.key_name, var.ec2_bastion_server.name, "keypair-ec2-bastion-server")
  ec2_bastion_kubectl_download_eks_version_map = {
    "1.29" = "1.28.3"
    "1.28" = "1.28.3"
    "1.27" = "1.27.7"
    "1.26" = "1.26.10"
    "1.25" = "1.25.15"
    "1.24" = "1.24.17"
    "1.23" = "1.23.17"
  }
  ec2_bastion_kubectl_download_eks_version_date_map = {
    "1.29" = "2023-11-14"
    "1.28" = "2023-11-14"
    "1.27" = "2023-11-14"
    "1.26" = "2023-11-14"
    "1.25" = "2023-11-14"
    "1.24" = "2023-11-14"
    "1.23" = "2023-11-14"
  }
}
