data "aws_availability_zones" "available_az" {
}

locals {
  public_cidr      = cidrsubnet(var.vpc_cidr, 1, 0)
  private_cidr     = cidrsubnet(var.vpc_cidr, 1, 1)
  private_bit_diff = var.private_subnet_size - element(split("/", local.private_cidr), 1)
  public_bit_diff  = var.public_subnet_size - element(split("/", local.public_cidr), 1)
}

################################################################################
# VPC  Module
################################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = [
    data.aws_availability_zones.available_az.names[1],
    data.aws_availability_zones.available_az.names[2],
    data.aws_availability_zones.available_az.names[3]
    ]
  private_subnets = [
    cidrsubnet(local.private_cidr, local.private_bit_diff,1), 
    cidrsubnet(local.private_cidr, local.private_bit_diff,2), 
    cidrsubnet(local.private_cidr, local.private_bit_diff,3)
    ]
  public_subnets  = [
    cidrsubnet(local.public_cidr, local.public_bit_diff,1), 
    cidrsubnet(local.public_cidr, local.public_bit_diff,2), 
    cidrsubnet(local.public_cidr, local.public_bit_diff,3)
    ]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = {
    Name = "MyVPC"
  }
}

################################################################################
# VPC Endpoints Module
################################################################################

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [data.aws_security_group.default.id]

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
    },
  }

  tags = {
    Name = "MyVPC-Endpoint"
  }
}

################################################################################
# Supporting Resources
################################################################################

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}