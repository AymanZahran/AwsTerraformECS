data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}

module "instance_profile" {
  source = "../aws_iam_instance_profile"
  name   = "${var.name}_profile"
}

###########################
# Application Load Balancer
###########################

resource "aws_lb" "load_balancer" {
  name               = "ext-alb-${var.name}"
  internal           = "false"
  load_balancer_type = "application"
  subnets                          = data.aws_vpc.vpc.public_subnets
  enable_cross_zone_load_balancing = "true"
  security_groups                  = [aws_security_group.webserver_security_group.id]
  idle_timeout                     = 60

  tags = merge(
    var.tags,
    {
      "Name" = "load-balancer-${var.name}"
    },
  )
}

resource "aws_lb_listener" "listener_target_group" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = "tg-ext-alb-asg-server"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.vpc_id

  health_check {
    interval = "30"
    port     = 80
    protocol = "HTTP"
    path     = var.health_check_path
    healthy_threshold = 3
  }

  tags = merge(
    var.tags,
    {
      "Name" = "tg-ext-alb-asg-server-${var.name}"
    },
  )
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.id
  alb_target_group_arn   = aws_lb_target_group.target_group.arn
}

locals {
  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.autoscaling_group_name)
    },
  )
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                 = var.autoscaling_group_name
  max_size             = var.max_instance_size
  min_size             = var.min_instance_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.app_private_subnets
  launch_configuration = aws_launch_configuration.launch_configuration.name
  health_check_type    = var.health_check_type
  target_group_arns    = [aws_lb_target_group.target_group.arn]
  tags                 = data.null_data_source.asg_tags.*.outputs
}

#Create Auto Scaling Policy to scale in and out based on CPU Consumption
resource "aws_autoscaling_policy" "autoscaling_policy" {
  name                   = var.autoscaling_policy
  policy_type            = var.autoscaling_policy_type
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
   target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.autoscaling_policy_predefined_metric_type
    }
    target_value = var.autoscaling_policy_target_value
  }
  depends_on = [aws_autoscaling_group.autoscaling_group]
}

resource "aws_launch_configuration" "launch_configuration" {
  name = var.launch_configuration_name

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp2"
  }

  image_id                    = var.ami
  instance_type               = var.instance_type
  iam_instance_profile        = module.instance_profile.name
  security_groups             = [aws_security_group.webserver_security_group.id]
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = var.user_data
}

data "null_data_source" "asg_tags" {
  count = length(keys(local.tags))

  inputs = {
    key                 = element(keys(local.tags), count.index)
    value               = element(values(local.tags), count.index)
    propagate_at_launch = "true"
  }
}

module "aws_s3" {
  source = "../aws_s3"
  bucket_name = "access-logs-azahran-account246176637906"
}
