terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.15.1"
}

variable "data_volumes" {
  type = map(object({
    size              = string
    availability_zone = string
  }))
  default = {
    "/dev/sdc" = {
      size              = "10"
      availability_zone = "ap-south-1b"
    }
    "/dev/sdd" = {
      size              = "10"
      availability_zone = "ap-south-1b"
    }
  }
}

variable "key_name" {
  type = object({
    name = string
  })
  default = {
    name = "inst_key"
  }
}

locals {
  common_tags = {
    "Terraform" = "true",
    "ebs_experiment" = "true"
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "dev_build" {
  name        = "dev_build"
  description = "Allow standard ssh ports inbound and everything else outbound."

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<change_me>/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "tls_private_key" "inst_key" {
  algorithm = "RSA"
}

resource "local_file" "key_file" {
  content  = "${tls_private_key.inst_key.private_key_pem}"
  filename = "${var.key_name.name}.pem"
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name.name
  public_key = tls_private_key.inst_key.public_key_openssh
  tags = local.common_tags
}

resource "aws_instance" "build_server" {
  # https://wiki.centos.org/Cloud/AWS
  # CentOS Linux 7:7.8.2003:ap-south-1:ami-0dd861ee19fd50a16:x86_64
  ami               = "ami-0dd861ee19fd50a16"
  instance_type     = "t2.micro"
  availability_zone = "ap-south-1b"
  key_name          = aws_key_pair.generated_key.key_name
  # key_name          = "yash-pem"

  tags = local.common_tags
}

resource "aws_ebs_volume" "data_vol" {
  for_each          = var.data_volumes
  availability_zone = each.value.availability_zone
  size              = each.value.size

  tags = local.common_tags
}

resource "aws_volume_attachment" "build_server_data" {
  for_each          = aws_ebs_volume.data_vol
  volume_id         = each.value.id
  device_name       = each.key
  instance_id       = aws_instance.build_server.id
}
