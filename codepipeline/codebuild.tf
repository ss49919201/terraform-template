resource "aws_s3_bucket" "by-tf-codebuild" {
  bucket = "by-tf-codebuild"
}

data "aws_iam_policy_document" "by-tf-codebuild-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "by-tf-codebuild" {
  name               = "by-tf-codebuild"
  assume_role_policy = data.aws_iam_policy_document.by-tf-codebuild-assume_role.json
}

data "aws_iam_policy_document" "by-tf-codebuild" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.by-tf-codebuild.arn,
      "${aws_s3_bucket.by-tf-codebuild.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "by-tf-codebuild" {
  role   = aws_iam_role.by-tf-codebuild.name
  policy = data.aws_iam_policy_document.by-tf-codebuild.json
}

resource "aws_codebuild_project" "example" {
  name          = "by-tf-codebuild"
  build_timeout = "5"
  service_role  = aws_iam_role.by-tf-codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.by-tf-codebuild.id}/build-log"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec = "codebuild/buildspec.yml"
  }
}
