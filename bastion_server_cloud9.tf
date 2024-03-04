resource "aws_cloud9_environment_ec2" "cloud9_bastion_server" {
  count         = var.cloud9_bastion_server.enabled ? 1 : 0
  instance_type = coalesce(var.cloud9_bastion_server.instance_type, "t2.micro")
  name          = "${var.name_prefix}${coalesce(var.cloud9_bastion_server.name, "c9-bastion-server")}"
  image_id      = "amazonlinux-2023-x86_64"
  subnet_id     = var.cloud9_bastion_server.subnet_id
  tags          = var.tags
}

