variable "aws_region" {}
variable "aws_profile" {}
data "aws_availability_zones" "available" {}
variable "vpc_cidr" {}

variable "cidrs" {
  type = "map"
}

variable "local_ip" {}
variable "domain_name" {}
variable "instance_type" {}
variable "dev_ami" {}
variable "dev_pub_key_path" {}