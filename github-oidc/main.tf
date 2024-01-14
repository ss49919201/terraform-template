terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.12.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # ダミーの値
  thumbprint_list = ["0123456789012345678901234567890123456789"]
}

resource "aws_iam_role" "github_actions_oidc" {
  name = "GitHubActionsOIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "" # GitHub の ID Provider が発行する OIDC Token の Sub
          },
        }
      }
    ]
  })
}