data "aws_availability_zones" "available_az" {
}

locals {
  public_cidr      = cidrsubnet(var.vpc_cidr, 1, 0)
  private_cidr     = cidrsubnet(var.vpc_cidr, 1, 1)
  private_bit_diff = var.private_subnet_size - element(split("/", local.private_cidr), 1)
  public_bit_diff  = var.public_subnet_size - element(split("/", local.public_cidr), 1)
}

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

  tags = var.tags
}