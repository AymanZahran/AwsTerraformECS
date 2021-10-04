################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = local.name
  cidr = var.vpc_ip_cidr
  azs                 = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  public_subnets      = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway = true
  single_nat_gateway = false
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []
  tags = merge(var.tags, {})
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
  tags = merge(var.tags, {})
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}
