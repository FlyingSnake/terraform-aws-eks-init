#### General Confing
variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "ID of the vpc where eks will be installed."
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-zA-Z0-9]{8,17}$", var.vpc_id))
    error_message = "[var.vpc_id] => ID of vpc is invalid."
  }
}

#### EKS Cluster Config
variable "eks_cluster" {
  description = "EKS cluster config"
  type = object({
    name       = string
    version    = string
    subnet_ids = list(string)
    endpoint_access = object({
      private            = bool
      public             = bool
      public_access_cidr = optional(string)
    })
    logging_options = object({
      api               = bool
      audit             = bool
      authenticator     = bool
      scheduler         = bool
      controllerManager = bool
    })
  })
  default = {
    name       = "eks-cluster"
    version    = "1.29"
    subnet_ids = []
    endpoint_access = {
      private            = true
      public             = false
      public_access_cidr = null
    }
    logging_options = {
      api               = true
      audit             = true
      authenticator     = false
      scheduler         = false
      controllerManager = false
    }
  }
  validation {
    condition     = length(var.eks_cluster.name) >= 3
    error_message = "[var.eks_cluster.name] => Length of cluster name must be at least 3"
  }
  validation {
    condition     = var.eks_cluster.endpoint_access.public ? can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.eks_cluster.endpoint_access.public_access_cidr)) : true
    error_message = "[var.eks_cluster.public_access_cidr] => The value must be in CIDR format (e.g., 192.168.100.14/24)."
  }
  validation {
    condition     = alltrue([for subnet_id in var.eks_cluster.subnet_ids : can(regex("^subnet-[a-zA-Z0-9]{8,17}$", subnet_id))])
    error_message = "[var.eks_cluster.subnet_ids] => ID of subnet is invalid."
  }
  validation {
    condition     = length(var.eks_cluster.subnet_ids) >= 2 ? true : false
    error_message = "[var.eks_cluster.subnet_ids] => There must be at least 2 subnets."
  }
  validation {
    condition     = can(tonumber(var.eks_cluster.version)) && tonumber(var.eks_cluster.version) > 1.28
    error_message = "[var.eks_cluster.version] => cluster version must be greater than 1.28."
  }
}

#### Nodegroup(EC2) Config
variable "eks_ec2_nodegroups" {
  description = "EKS ec2 nodegroups config"
  type = list(object({
    name          = string
    capacity_type = optional(string) // SPOT or ON_DEMAND 
    subnet_ids    = list(string)
    instance_type = list(string)
    instance_number = object({
      min     = number
      desired = number
      max     = number
    })
    ssm_agent_enabled = bool
    ssh_config = object({
      enabled                   = bool
      key_name                  = optional(string)
      source_security_group_ids = optional(list(string))
    })
    node_labels = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
  }))
  default = []


  validation {
    condition     = alltrue([for ng in var.eks_ec2_nodegroups : length(ng.name) >= 3])
    error_message = "[var.eks_ec2_nodegroups[*].name] => Length of nodegroup name must be at least 3"
  }
  validation {
    condition     = alltrue([for ng in var.eks_ec2_nodegroups : length(ng.subnet_ids) > 0])
    error_message = "[var.eks_ec2_nodegroups[*].subnet_ids] =>  The length of subnet_ids must be at least 1"
  }
  validation {
    condition = alltrue([
      for ng in var.eks_ec2_nodegroups : alltrue([
        for subnet_id in ng.subnet_ids : can(regex("^subnet-[a-zA-Z0-9]{8,17}$", subnet_id))
      ])
    ])
    error_message = "[var.eks_ec2_nodegroups[*].subnet_ids] => ID of subnet is invalid."
  }
  validation {
    condition = alltrue([
      for ng in var.eks_ec2_nodegroups : alltrue([
        for sg_id in coalesce(ng.ssh_config.source_security_group_ids, []) : can(regex("^sg-[a-zA-Z0-9]{8,17}$", sg_id))
      ])
    ])
    error_message = "[var.eks_ec2_nodegroups[*].ssh_config.source_security_group_ids] => ID of security group is invalid."
  }
  validation {
    condition     = alltrue([for ng in var.eks_ec2_nodegroups : contains(["SPOT", "ON_DEMAND"], coalesce(ng.capacity_type, "ON_DEMAND"))])
    error_message = "[var.eks_ec2_nodegroups[*].capacity_type] => capacity_type must be in ['SPOT','ON_DEMAND']"
  }
  validation {
    condition     = alltrue([for ng in var.eks_ec2_nodegroups : ng.instance_number.min <= ng.instance_number.desired])
    error_message = "[var.eks_ec2_nodegroups[*].min|desired] => 'min'count must be smaller or equal than 'desired'"
  }
  validation {
    condition     = alltrue([for ng in var.eks_ec2_nodegroups : ng.instance_number.desired <= ng.instance_number.max])
    error_message = "[var.eks_ec2_nodegroups[*].desired|max] => 'desired'count must be smaller or equal than 'max'"
  }
  validation {
    condition = alltrue([
      for ng in var.eks_ec2_nodegroups : ng.taints != null ? alltrue([
        for taint in ng.taints : contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], taint.effect)
      ]) : true
    ])
    error_message = "[var.eks_ec2_nodegroups[*].taints] => All taints.effect must be one of 'NO_SCHEDULE', 'NO_EXECUTE', or 'PREFER_NO_SCHEDULE'."
  }
}

#### Nodegroup common ssh key name
variable "eks_ec2_node_common_ssh_key_name" {
  description = "Shared ec2 nodegroup ssh-key pair name"
  type        = string
  default     = "eks-ec2-nodegroup-common-ssh-key"
}


#### Nodegroup (Fargate) Config
variable "eks_fargate_nodegroups" {
  description = "EKS fargate nodegroups config"
  type = list(object({
    profile_name = string
    namespace    = string
    subnet_ids   = list(string)
    instance_number = object({
      min     = number
      desired = number
      max     = number
    })
    node_labels = optional(map(string))
  }))
  default = []


  validation {
    condition     = alltrue([for ng in var.eks_fargate_nodegroups : length(ng.profile_name) >= 3])
    error_message = "[var.eks_fargate_nodegroups[*].profile_name] => Length of nodegroup name must be at least 3"
  }
  validation {
    condition = alltrue([
      for ng in var.eks_fargate_nodegroups : length(ng.subnet_ids) > 0
    ])
    error_message = "[var.eks_fargate_nodegroups[*].subnet_ids] =>  The length of subnet_ids must be at least 1"
  }
  validation {
    condition = alltrue([
      for ng in var.eks_fargate_nodegroups : alltrue([
        for subnet_id in ng.subnet_ids : can(regex("^subnet-[a-zA-Z0-9]{8,17}$", subnet_id))
      ])
    ])
    error_message = "[var.eks_fargate_nodegroups[*].subnet_ids] => ID of subnet is invalid."
  }
  validation {
    condition     = alltrue([for ng in var.eks_fargate_nodegroups : ng.instance_number.min <= ng.instance_number.desired])
    error_message = "[var.eks_fargate_nodegroups[*].min|desired] => 'min'count must be smaller or equal than 'desired'"
  }
  validation {
    condition     = alltrue([for ng in var.eks_fargate_nodegroups : ng.instance_number.desired <= ng.instance_number.max])
    error_message = "[var.eks_fargate_nodegroups[*].desired|max] => 'desired'count must be smaller or equal than 'max'"
  }
  validation {
    condition     = alltrue([for ng in var.eks_fargate_nodegroups : length(ng.profile_name) >= 3])
    error_message = "[var.eks_fargate_nodegroups[*].profile_name] => Length of nodegroup name must be at least 3"
  }
}


#### Bastion Server
variable "ec2_bastion_server" {
  description = "EC2 bastion server config"
  type = object({
    enabled                       = bool
    name                          = string
    subnet_id                     = string
    ami                           = optional(string)
    instance_type                 = optional(string)
    additional_security_group_ids = optional(list(string))
    ssm_agent_enabled             = bool
    ssh_config = object({
      enabled  = bool
      new      = bool
      key_name = optional(string)
    })
  })

  default = {
    enabled       = false
    name          = "ec2-bastion-server"
    subnet_id     = null
    ami           = "ami-051f7e7f6c2f40dc1"
    instance_type = "t2.micro"
    ssh_config = {
      enabled  = false
      new      = true
      key_name = ""
    }
    additional_security_group_ids = []
    ssm_agent_enabled             = true
  }

  validation {
    condition     = var.ec2_bastion_server.enabled ? length(var.ec2_bastion_server.name) >= 3 : true
    error_message = "[var.ec2_bastion_server.name] => Length of bastion server name must be at least 3"
  }
  validation {
    condition     = var.ec2_bastion_server.enabled ? can(regex("^subnet-[a-zA-Z0-9]{8,17}$", var.ec2_bastion_server.subnet_id)) : true
    error_message = "[var.ec2_bastion_server.subnet_id] => ID of subnet is invalid."
  }
  validation {
    condition = (var.ec2_bastion_server.enabled && var.ec2_bastion_server.additional_security_group_ids != null
      ? alltrue([for sg_id in var.ec2_bastion_server.additional_security_group_ids : can(regex("^sg-[a-zA-Z0-9]{8,17}$", sg_id))])
    : true)
    error_message = "[var.ec2_bastion_server.additional_security_group_ids] => ID of security group is invalid."
  }

}

#### Cloud9 config
variable "cloud9_bastion_server" {
  description = "Clou9 bastion server config"
  type = object({
    enabled       = bool
    name          = string
    instance_type = optional(string)
    subnet_id     = string
  })
  default = {
    enabled       = false
    name          = "c9-bastion-server"
    instance_type = "t2.micro"
    subnet_id     = null
  }

  validation {
    condition     = var.cloud9_bastion_server.enabled ? length(var.cloud9_bastion_server.name) >= 3 : true
    error_message = "[var.cloud9_bastion_server.name] => Length of cloud9 name must be at least 3"
  }
  validation {
    condition     = var.cloud9_bastion_server.enabled ? can(regex("^subnet-[a-zA-Z0-9]{8,17}$", var.cloud9_bastion_server.subnet_id)) : true
    error_message = "[var.cloud9_bastion_server.subnet_id] => ID of subnet is invalid."
  }
}


#### VPC Endpoints
variable "vpc_endpoint" {
  description = "Interface VPCEndpoints config (if the eks node group has an airgapped subnet)"
  type = object({
    enabled    = bool
    subnet_ids = list(string)
    services   = optional(list(string))
  })
  default = {
    enabled    = false
    subnet_ids = []
    services   = ["ec2", "ec2messages", "ecr.dkr", "ecr.api", "s3", "elasticloadbalancing", "xray", "logs", "sts", "ssm", "ssmmessages"]
  }
  validation {
    condition     = var.vpc_endpoint.enabled ? length(var.vpc_endpoint.subnet_ids) > 0 : true
    error_message = "[var.vpc_endpoint.subnet_ids] =>  The length of subnet_ids must be at least 1"
  }
  validation {
    condition     = var.vpc_endpoint.enabled ? alltrue([for subnet_id in var.vpc_endpoint.subnet_ids : can(regex("^subnet-[a-zA-Z0-9]{8,17}$", subnet_id))]) : true
    error_message = "[var.vpc_endpoint.subnet_ids] => ID of subnet is invalid."
  }
}


