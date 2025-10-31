# -------------------------
# Provider Configuration
# -------------------------
provider "aws" {
  region = var.aws_region
}

# -------------------------
# Variables
# -------------------------
variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for Subnet"
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for Subnet"
  default     = "ap-south-1a"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  default     = "ami-01760eea5c574eb86"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name for EC2"
  default     = "assg_key"
}

variable "bucket_prefix" {
  description = "Prefix for S3 bucket name"
  default     = "my-terraform-s3-bucket-shagun"
}

# -------------------------
# Resources
# -------------------------

resource "random_id" "rand" {
  byte_length = 4
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyMainVPC"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "MyMainSubnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "MyMainIGW"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = "MyMainRouteTable"
  }
}

resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_security_group" "main_sg" {
  name        = "main-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyMainSecurityGroup"
  }
}

resource "aws_instance" "main_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.main_subnet.id
  vpc_security_group_ids      = [aws_security_group.main_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "MyMainEC2"
  }
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "${var.bucket_prefix}-${random_id.rand.hex}"
  acl    = "private"

  tags = {
    Name        = "MyS3Bucket"
    Environment = "Dev"
  }
}

# -------------------------
# Outputs
# -------------------------
output "ec2_public_ip" {
  value = aws_instance.main_ec2.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}
