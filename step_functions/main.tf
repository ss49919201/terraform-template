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
  region = "ap-northeast-1"
}

data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

module "vpc" {
  source = "./modules/vpc"
}

module "ecr_repository" {
  source              = "./modules/ecr"
  ecr_repository_name = "example"
}

module "ecs_task" {
  source                   = "./modules/ecs"
  vpc_id                   = module.vpc.vpc_id
  ecr_repository_url       = module.ecr_repository.ecr_repository_url
  ecs_cluster_name         = "example"
  ecs_task_definition_name = "example"
  aws_account_id           = local.aws_account_id
}

module "lambda" {
  source               = "./modules/lambda"
  lambda_function_name = "example"
}
