data "aws_vpc" "vpc" {
  most_recent = true
  owners = ["self"]
  tags = {
    Name   = "MyVPC"
  }
}

module "vpc" {
  source   = "./modules/aws_vpc/"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_ip_cidr
  tags     =  merge(var.tags, {
    Name   = "MyVPC"
  })
}

module "web_server" {
  source = "./modules/aws_asg_server"

  name                      = var.name
  vpc_id                    = aws_vpc.vpc.outputs.vpc_id
  app_private_subnets       = aws_vpc.vpc.outputs.private_subnets
  volume_size               = var.volume_size
  tags                      = var.tags
  region                    = var.region
  ami                       = "ami-082b5a644766e0e6f"
  user_data                 = data.template_file.webserver_launch_configuration_user_data.rendered
}

data "template_file" "webserver_launch_configuration_user_data" {
  template = file("${path.module}/template/user_data.tpl")
}

