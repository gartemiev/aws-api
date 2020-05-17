provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# IAM
#S3 Access Role
resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name   = "s3_access_policy"
  policy = ""
  role   = "${aws_iam_role.s3_access_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
         "Effect": "Allow",
         "Action": "s3:*",
         "Resource": "*"
       }
    ]
  }
EOF
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
         "Service": "ec2.amazonaws.com"
      },
       "Effect": "Allow",
       "Sid": ""
     }
   ]
  }
EOF
}

# VPC
resource "aws_vpc" "wp_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "wp_vpc"
  }
}

# Internet gateway
resource "aws_internet_gateway" "wp_internet" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  tags {
    Name = "wp_igw"
  }
}

resource "aws_route_table" "wp_public_rt" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_internet.id}"
  }

  tags {
    Name = "wp_public"
  }
}

resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = "${aws_vpc.wp_vpc.default_route_table_id}"

  tags {
    Name = "wp_private"
  }
}

# Subnets
resource "aws_subnet" "wp_public1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_public1"
  }
}

resource "aws_subnet" "wp_public2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "wp_public2"
  }
}

resource "aws_subnet" "wp_private1_subnet" {
  vpc_id            = "${aws_vpc.wp_vpc.id}"
  cidr_block        = "${var.cidrs["private1"]}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_private1"
  }
}

resource "aws_subnet" "wp_private2_subnet" {
  vpc_id            = "${aws_vpc.wp_vpc.id}"
  cidr_block        = "${var.cidrs["private2"]}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "wp_private2"
  }
}

resource "aws_subnet" "wp_rds1_subnet" {
  vpc_id            = "${aws_vpc.wp_vpc.id}"
  cidr_block        = "${var.cidrs["rds1"]}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_rds1"
  }
}

resource "aws_subnet" "wp_rds2_subnet" {
  vpc_id            = "${aws_vpc.wp_vpc.id}"
  cidr_block        = "${var.cidrs["rds2"]}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "wp_rds2"
  }
}

resource "aws_subnet" "wp_rds3_subnet" {
  vpc_id            = "${aws_vpc.wp_vpc.id}"
  cidr_block        = "${var.cidrs["rds3"]}"
  availability_zone = "${data.aws_availability_zones.available.names[2]}"

  tags {
    Name = "wp_rds3"
  }
}

# Subnet associations
resource "aws_route_table_association" "wp_public1_assc" {
  subnet_id      = "${aws_subnet.wp_public1_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_public2_assc" {
  subnet_id      = "${aws_subnet.wp_public2_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_private1_assc" {
  subnet_id      = "${aws_subnet.wp_private1_subnet.id}"
  route_table_id = "${aws_default_route_table.wp_private_rt.id}"
}

resource "aws_route_table_association" "wp_private2_assc" {
  subnet_id      = "${aws_subnet.wp_private2_subnet.id}"
  route_table_id = "${aws_default_route_table.wp_private_rt.id}"
}

# Security groups
resource "aws_security_group" "wp_dev_sg" {
  name        = "wp_dev_sg"
  description = "used for access to dev inst"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  # SSH
  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["${var.local_ip}"]
  }

  # HTTP
  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["${var.local_ip}"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Private security group

resource "aws_security_group" "wp_private_sg" {
  name        = "wp_private_sg"
  description = "for internal access only"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  # Access from VPC
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
}

#S3 Bucket
resource "random_id" "wp_code_bucket" {
  byte_length = 2
}

resource "aws_s3_bucket" "code" {
  bucket = "${var.domain_name}-${random_id.wp_code_bucket.dec}"
  acl = "private"
  force_destroy = true
}

#Dev key pair
resource "aws_key_pair" "wp_auth" {
  public_key = "${file(var.dev_pub_key_path)}"
}

#Dev server
resource "aws_instance" "wp_dev" {
  ami = "${var.dev_ami}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.wp_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.wp_dev_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.s3_access_profile.id}"
  subnet_id = "${aws_subnet.wp_private1_subnet.id}"
  
  tags {
    Name = "wp_dev"
  }
}

