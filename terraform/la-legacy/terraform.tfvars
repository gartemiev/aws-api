aws_profile = "superhero"
aws_region = "us-east-1"
vpc_cidr   = "10.0.0.0/16"
cidrs = {
  public1 = "10.0.1.0/24"
  public2 = "10.0.2.0/24"
  private1 = "10.0.3.0/24"
  private2 = "10.0.4.0/24"
  rds1 = "10.0.5.0/24"
  rds2 = "10.0.6.0/24"
  rds3 = "10.0.7.0/24"
}
local_ip = "91.225.201.58/32"
domain_name = "dev"
instance_type = "t2.micro"
dev_ami = "ami-b73b63a0"
dev_pub_key_path = "~/.ssh/id_rsa.pub"