terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "app_server" {
  ami                    = "ami-08d70e59c07c61a3a"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-c890639b"]
  subnet_id              = "subnet-f09073ba"

  tags = {
    Name = var.instance_name
  }
}
