variable "aws_access_key" {
    description = "AWS accesskey"
    type = string
}

variable "aws_secret_key" {
    description = "AWS secretkey"
    type = string
}

variable "aws_region" {
  description = "AWS region"
  type = string
}

variable "aws_vpc_cidr_block" {
  description = "VPC cidr block"
  type = string
}

variable "aws_subnet_cidr_block" {
  description = "Subnet cidr block"
  type = string
}

variable "aws_ami" {
  description = "AMI for the EC2 instance"
  type = string
}

variable "aws_availability_zone" {
  description = "Availability zone for your EC2 instance"
  type = string
}

variable "aws_instance_type" {
  description = "EC2 instance type"
  type = string
}

variable "aws_key_name" {
  description = "Key pair for your EC2 instance"
  type = string
}
