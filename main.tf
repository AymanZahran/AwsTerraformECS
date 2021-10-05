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

################################################################################
# ECS Module
################################################################################
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  name               = l"MyECS"
  container_insights = true
  capacity_providers = ["FARGATE", "FARGATE_SPOT", aws_ecs_capacity_provider.prov1.name]
  default_capacity_provider_strategy = [{
    capacity_provider = aws_ecs_capacity_provider.prov1.name # "FARGATE_SPOT"
    weight            = "1"
  }]

  tags = {
    Name = "ECS"
  }
}

module "ec2_profile" {
  source = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  name = "EC2-Profile"
  tags = {
    Name = "EC2-Profile"
  }
}

resource "aws_ecs_capacity_provider" "prov1" {
  name = "prov1"

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg.autoscaling_group_arn
  }

}

################################################################################
# ECS Services Module
################################################################################
module "hello_world" {
  source  = "terraform-aws-modules/ecs/aws//examples/complete-ecs/service-hello-world"
  cluster_id = module.ecs.ecs_cluster_id
}

#----- ECS  Resources--------

#For now we only use the AWS ECS optimized ami <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html>
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

################################################################################
# ASG Module
################################################################################
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  name = "ECS-ASG"

  # Launch configuration
  lc_name   = "ECS-LC"
  use_lc    = true
  create_lc = true

  image_id                  = data.aws_ami.amazon_linux_ecs.id
  instance_type             = "t2.micro"
  security_groups           = [module.vpc.default_security_group_id]
  iam_instance_profile_name = module.ec2_profile.iam_instance_profile_id
  user_data                 = data.template_file.user_data.rendered

  # Auto scaling group
  vpc_zone_identifier       = module.vpc.private_subnets
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 0 # we don't need them for the example
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = local.environment
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = local.name
      propagate_at_launch = true
    },
  ]
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = "ECS-Cluster"
  }
}