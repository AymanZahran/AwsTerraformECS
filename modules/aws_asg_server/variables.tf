//----------------------------------------------------------------------
// Shared  Variables
//----------------------------------------------------------------------
variable "name" {
  type        = string
  description = "EC2 Instance Name"
}

variable "region" {
  default = "us-west-2"
}

variable "tags" {
  description = "tags to propogate to all supported resources"
  type        = map(string)
}

variable "vpc_id" {
}

variable "ami" {
  type = string
  description = "AMI ID"
}

//----------------------------------------------------------------------
// Security Groups Variables
//----------------------------------------------------------------------

variable "sg_webserver" {
  description = "Name of the webserver ASG Security Group"
  default     = "sg_webserver_asg"
}

//----------------------------------------------------------------------
// Autoscaling Group Variables
//----------------------------------------------------------------------

variable "autoscaling_group_name" {
  description = "The name for the autoscaling group for the web."
  default     = "web-asg"
}

variable "autoscaling_policy" {
  description = "The name for the autoscaling policy for the web."
  default     = "web-asg-as-policy"
}

variable "autoscaling_policy_type" {
  description = "The type for the autoscaling policy. SimpleScaling, StepScaling, TargetTrackingScaling, or PredictiveScaling"
  default     = "TargetTrackingScaling"
}

variable "autoscaling_policy_predefined_metric_type" {
  description = "The type for the metric. CPU, Memory, .."
  default     = "ASGAverageCPUUtilization"
}

variable "autoscaling_policy_target_value" {
  description = "The target value for the autoscale policy"
  default     = 40.0
}

variable "max_instance_size" {
  description = "The max instances number for the webserver."
  default     = 3
}

variable "min_instance_size" {
  description = "The min instance number for the webserver."
  default     = 1
}

variable "desired_capacity" {
  description = "The desired capacity of number of instances for the webserver."
  default     = 1
}

variable "app_private_subnets" {
  type    = list(string)
  default = []
}

variable "health_check_type" {
  default = "EC2"
}

variable "health_check_path" {
  type        = string
  description = "ALB Health Check Path"
  default     = "/"
}

//----------------------------------------------------------------------
// Launch Configuration Variables
//----------------------------------------------------------------------

variable "launch_configuration_name" {
  description = "The name for launch configuration for the cluster."
  default     = "web-lc"
}

variable "instance_type" {
  description = "The instance type for EC2 instances for the cluster."
  default     = "t3.small"
}

variable "volume_size" {
  description = "Size of root EBS volume of the container instance"
  default     = "8"
}

variable "associate_public_ip_address" {
  default = false
}

//----------------------------------------------------------------------
// IAM Variables
//----------------------------------------------------------------------

variable "webserver_instance_role" {
  default = "webserver_instance_role"
}

variable "webserver_instance_policy" {
  default = "webserver_instance_policy"
}

variable "webserver_instance_profile" {
  default = "webserver_instance_profile"
}

variable "user_data" {
  type        = string
  description = "User data to execute on the ec2 instance"
  default     = ""
}
