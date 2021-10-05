variable "region" {
  type = string
  description = "aws region"
  default = "us-west-2"
}

variable "tags" {
  description = "tags to propogate to all supported resources"
  type        = string
}

variable "az_count" {
  description = "the number of AZs to deploy infrastructure to"
  default     = 3
}

variable "vpc_name" {
  description = "name of the VPC to create"
  default = "MyVPC"
}

variable "vpc_cidr" {
  description = "CIDR associated with the VPC to be created"
  default     = "10.0.0.0/16"
}

variable "private_subnet_size" {
  default = 24
}

variable "public_subnet_size" {
  default = 26
}
