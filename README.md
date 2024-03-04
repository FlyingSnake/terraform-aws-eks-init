# terraform-aws-eks

AWS EKS Initialization Module

## Usage

```hcl
module "eks-init" {
  source      = "FlyingSnake/eks-init/aws"

  name_prefix = "TF-"

  tags = {
    Terraform       = "true"
  }

  vpc_id = "vpc-xxxx"

  eks_cluster = {
    name    = "eks-cluster"
    version = "1.29"
    endpoint_access = {
      private = true
      public  = false
    }
    subnet_ids = ["subnet-xxxx", "subnet-xxxx"]
    logging_options = {
      api               = true
      audit             = true
      authenticator     = false
      controllerManager = false
      scheduler         = false
    }
  }

  eks_ec2_nodegroups = [
    {
      name              = "ondemand-nodegroup-example"
      instance_type     = ["t3.large"]
      subnet_ids        = ["subnet-xxxx", "subnet-xxxx"]
      ssm_agent_enabled = true
      ssh_config = {
        enabled                   = true
        source_security_group_ids = ["sg-xxxx"]
      }
      instance_number = {
        min     = 1
        desired = 1
        max     = 2
      }
    },
    {
      name          = "spot-nodegroup-example"
      instance_type = ["t3.large"]
      capacity_type = "SPOT"
      subnet_ids        = ["subnet-xxxx", "subnet-xxxx"]
      ssm_agent_enabled = true
      ssh_config = {
        enabled = false
      }
      instance_number = {
        min     = 1
        desired = 1
        max     = 2
      }
      node_labels = {
        node_instance_type = "spot"
      }
      taints = [
        {
          key    = "executeSpotInstance"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  ]

  eks_fargate_nodegroups = [
    {
      profile_name = "fargate-nodegroup-example"
      namespace    = "default"
      subnet_ids   = ["subnet-xxxx", "subnet-xxxx"]
      instance_number = {
        min     = 1
        desired = 2
        max     = 2
      }
    }
  ]

  # If the EKS node belongs to an airgapped subnet, configure it
  vpc_endpoint = {
    enabled    = true
    subnet_ids = ["subnet-xxxx", "subnet-xxxx"]
  }

  ec2_bastion_server = {
    enabled           = true
    name              = "ec2-bastion-server"
    subnet_id         = "subnet-xxxx"
    ssm_agent_enabled = true
    ssh_config = {
      enabled = true
      new     = true
    }
  }

  cloud9_bastion_server = {
    enabled   = true
    name      = "cloud9-bastion-server"
    subnet_id = "subnet-xxxx"
  }
}
```

## Input

| Name                             | Description                                                                       | Type         |
| -------------------------------- | --------------------------------------------------------------------------------- | ------------ |
| name_prefix                      | Pre Name attached to the name of the AWS resource being created                   | string       |
| tags                             | Tags to be attached to created AWS resources                                      | object       |
| vpc_id                           | ID of the vpc where eks will be installed                                         | string       |
| eks_cluster                      | EKS cluster config                                                                | object       |
| eks_ec2_nodegroups               | EKS ec2 nodegroups config                                                         | list(object) |
| eks_ec2_node_common_ssh_key_name | Shared ec2 nodegroup ssh-key pair name (default=eks-ec2-nodegroup-common-ssh-key) | string       |
| eks_fargate_nodegroups           | EKS fargate nodegroups config                                                     | list(object) |
| ec2_bastion_server               | EC2 bastion server config                                                         | string       |
| cloud9_bastion_server            | Clou9 bastion server config                                                       | string       |
| vpc_endpoint                     | Interface VPCEndpoints config (if the eks node group has an airgapped subnet)     | object       |

## Output

| Name                       | Description                   | Type         |
| -------------------------- | ----------------------------- | ------------ |
| eks_version                | EKS version                   | string       |
| eks_cluster_name           | EKS cluster name              | string       |
| eks_cluster_endpoint       | EKS endpoint                  | string       |
| eks_oidc_id                | EKS OIDC id                   | string       |
| eks_nodegroup_ec2_list     | EKS nodegroup name list       | list(string) |
| eks_nodegroup_fargate_list | EKS fargate profile name list | list(string) |
| bastion_ec2_arn            | EC2 bastion server arn        | string       |
| bastion_cloud9_arn         | Cloud9 bastion server arn     | string       |
| enabled_vpc_endpoint_list  | Created VPC endpoints list    | list(string) |

## Resources

| Name                                                             | Type                           |
| ---------------------------------------------------------------- | ------------------------------ |
| eks_cluster                                                      | aws_eks_cluster                |
| eks_cluster_role                                                 | aws_iam_role                   |
| eks_cluster_role_attach_AmazonEKSClusterPolicy                   | aws_iam_role_policy_attachment |
| eks_cluster_role_attach_AmazonEKSServicePolicy                   | aws_iam_role_policy_attachment |
| aws_iam_openid_connect_provider                                  | eks_oidc_provider              |
| eks_cluster_sg                                                   | aws_security_group             |
| eks_ec2_nodegroups                                               | aws_eks_node_group[]           |
| eks_ec2_node_role                                                | aws_iam_role                   |
| eks_ec2_node_ssm_agent_role                                      | aws_iam_role                   |
| eks_ec2_node_role_attach_AmazonEKSWorkerNodePolicy               | aws_iam_role_policy_attachment |
| eks_ec2_node_role_attach_AmazonEKS_CNI_Policy                    | aws_iam_role_policy_attachment |
| eks_ec2_node_role_attach_AmazonEC2ContainerRegistryReadOnly      | aws_iam_role_policy_attachment |
| eks_ec2_node_profile                                             | aws_iam_instance_profile       |
| eks_ec2_node_ssma_role_attach_AmazonSSMManagedInstancre          | aws_iam_role_policy_attachment |
| eks_ec2_node_ssma_role_attach_AmazonEKSWorkerNodePolicy          | aws_iam_role_policy_attachment |
| eks_ec2_node_ssma_role_attach_AmazonEKS_CNI_Policy               | aws_iam_role_policy_attachment |
| eks_ec2_node_ssma_role_attach_AmazonEC2ContainerRegistryReadOnly | aws_iam_role_policy_attachment |
| eks_ec2_node_ssma_profile                                        | aws_iam_instance_profile       |
| eks_ec2_node_key_alorithm                                        | tls_private_key                |
| eks_ec2_node_private_key                                         | local_file                     |
| eks_ec2_node_public_key                                          | local_file                     |
| eks_ec2_node_key_pair                                            | aws_key_pair                   |
| eks_fargate_profile                                              | aws_eks_fargate_profile[]      |
| eks_fargate_role                                                 | aws_iam_role                   |
| eks_fargate_role_attch_AmazonEKSFargatePodExecutionRolePolicy    | aws_iam_role_policy_attachment |
| ec2_bastion_server                                               | aws_instance                   |
| ec2_bastion_server_role                                          | aws_iam_role                   |
| ec2_bastion_server_role_attach_AmazonSSMManagedInstanceCore      | aws_iam_role_policy_attachment |
| ec2_bastion_server_profile                                       | aws_iam_instance_profile       |
| ec2_bastion_server_sg                                            | aws_security_group             |
| ec2_bastion_key_alorithm                                         | tls_private_key                |
| ec2_bastion_private_key                                          | local_file                     |
| ec2_bastion_public_key                                           | local_file                     |
| ec2_bastion_key_pair                                             | aws_key_pair                   |
| cloud9_bastion_server                                            | aws_cloud9_environment_ec2     |
| vpce_sg                                                          | aws_security_group             |
| vpce_ec2                                                         | aws_vpc_endpoint               |
| vpce_ec2messages                                                 | aws_vpc_endpoint               |
| vpce_ecr_dkr                                                     | aws_vpc_endpoint               |
| vpce_ecr_api                                                     | aws_vpc_endpoint               |
| vpce_s3                                                          | aws_vpc_endpoint               |
| vpce_elb                                                         | aws_vpc_endpoint               |
| vpce_xray                                                        | aws_vpc_endpoint               |
| vpce_cloudwatch                                                  | aws_vpc_endpoint               |
| vpce_sts                                                         | aws_vpc_endpoint               |
| vpce_ssm                                                         | aws_vpc_endpoint               |
| vpce_ssmmessages                                                 | aws_vpc_endpoint               |
