locals {
  vpc_endpoints_default = ["ec2", "ec2messages", "ecr.dkr", "ecr.api", "s3", "elasticloadbalancing", "xray", "logs", "sts", "ssm", "ssmmessages"]
}

resource "aws_security_group" "vpce_sg" {
  count       = var.vpc_endpoint.enabled ? 1 : 0
  name        = "${var.name_prefix}sg-vpce"
  tags        = merge({ Name = "${var.name_prefix}sg-vpce" }, var.tags)
  description = "Security groups commonly used in VPCE"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "vpce_ec2" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "ec2") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-ec2" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_ec2messages" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "ec2messages") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-ec2messages" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_ecr_dkr" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "ecr.dkr") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-ecr-dkr" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_ecr_api" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "ecr.api") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-ecr-api" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_s3" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "s3") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  dns_options {
    private_dns_only_for_inbound_resolver_endpoint = false
  }
  tags = merge({ Name = "${var.name_prefix}vpce-s3" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_elb" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "elasticloadbalancing") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-elb" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_xray" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "xray") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.xray"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-xray" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_cloudwatch" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "logs") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-xray" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_sts" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "sts") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-sts" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_ssm" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "ssm") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-ssm" }, var.tags)
}

resource "aws_vpc_endpoint" "vpce_ssmmessages" {
  count               = var.vpc_endpoint.enabled && contains(coalesce(var.vpc_endpoint.services, local.vpc_endpoints_default), "ssmmessages") ? 1 : 0
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint.subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg[0].id]
  private_dns_enabled = true
  tags                = merge({ Name = "${var.name_prefix}vpce-ssmmessages" }, var.tags)
}

