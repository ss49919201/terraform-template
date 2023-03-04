// Lambda Function
resource "aws_lambda_function" "lambda_function" {
  architectures = [
    "x86_64",
  ]
  filename                       = data.archive_file.lambda_zip.output_path
  function_name                  = var.lambda_function_name
  handler                        = "main"
  layers                         = []
  memory_size                    = 512
  package_type                   = "Zip"
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.role_for_lambda.arn
  runtime                        = "go1.x"
  tags                           = {}
  tags_all                       = {}
  timeout                        = 15

  ephemeral_storage {
    size = 512
  }

  tracing_config {
    mode = "PassThrough"
  }
}

// IAM Role
resource "aws_iam_role" "role_for_lambda" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  managed_policy_arns = [
    aws_iam_policy.policy_for_lambda.arn,
  ]
  max_session_duration = 3600
  name                 = "role_for_lambda"
  path                 = "/service-role/"
  tags                 = {}
  tags_all             = {}
}

// IAM Policy
resource "aws_iam_policy" "policy_for_lambda" {
  depends_on = [
    aws_cloudwatch_log_group.log_group_for_lambda
  ]
  name = "policy_for_lambda"
  path = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action   = "logs:CreateLogGroup"
          Effect   = "Allow"
          Resource = aws_cloudwatch_log_group.log_group_for_lambda.arn
        },
        {
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect = "Allow"
          Resource = [
            aws_cloudwatch_log_group.log_group_for_lambda.arn,
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
  tags     = {}
  tags_all = {}
}

// CloudWatch Log
resource "aws_cloudwatch_log_group" "log_group_for_lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 0
}

// Script
// terraform apply したパスで実行される
resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "cd ./src/lambda && GOOS=linux GOARCH=amd64 go build -o main main.go"
  }
}

// Zip
// terraform apply したパスからの相対パス
data "archive_file" "lambda_zip" {
  depends_on = [
    null_resource.build
  ]
  type        = "zip"
  source_file = "./src/lambda/main"
  output_path = "./src/lambda/main.zip"
}
