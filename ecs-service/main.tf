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

locals {
  subnet_public_param_map = {
    az1a = {
      availability_zone = "ap-northeast-1a"
      cidr_block        = "10.0.1.0/24"
    }
    az1c = {
      availability_zone = "ap-northeast-1c"
      cidr_block        = "10.0.2.0/24"
    }
  }
  subnet_private_param_map = {
    az1a = {
      availability_zone = "ap-northeast-1a"
      cidr_block        = "10.0.3.0/24"
    }
    az1c = {
      availability_zone = "ap-northeast-1c"
      cidr_block        = "10.0.4.0/24"
    }
  }
}

// VPC
resource "aws_vpc" "app" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

// VPC Endpoint
resource "aws_security_group" "vpc_endpoint" {
  name   = "vpc_endoint_sg"
  vpc_id = aws_vpc.app.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.app.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.app.cidr_block]
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for v in aws_subnet.private : v.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for v in aws_subnet.private : v.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for v in aws_subnet.private : v.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private.id
}

// Subnet
resource "aws_subnet" "public" {
  for_each          = local.subnet_public_param_map
  vpc_id            = aws_vpc.app.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
}

resource "aws_subnet" "private" {
  for_each          = local.subnet_private_param_map
  vpc_id            = aws_vpc.app.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
}

// Route Table
resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table_association" "app_private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

// ELB
resource "aws_security_group" "alb_app" {
  name   = "alb_app"
  vpc_id = aws_vpc.app.id

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
}

// `ValidationError: At least two subnets in two different Availability Zones must be specified`が発生するので、
// Subnet を2つ以上作成する必要がある。
resource "aws_lb" "app" {
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_app.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_lb_target_group" "app" {
  port        = 80
  protocol    = "HTTP"
  target_type = "ip" // for Fargate
  vpc_id      = aws_vpc.app.id
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

// ECR
resource "aws_ecr_repository" "app" {
  name = "app"
}

// ECS
resource "aws_ecs_cluster" "app" {
  name = "app"
}

resource "aws_security_group" "ecs_service_app" {
  vpc_id = aws_vpc.app.id

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

}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.ecs_service_app.id]
    subnets         = [for subnet in aws_subnet.private : subnet.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.id
    container_name   = "app"
    container_port   = 80
  }
}

data "aws_iam_policy_document" "ecs_task_execution" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "ecs_task_execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_executionh" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "app"
  retention_in_days = 180
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = aws_ecr_repository.app.repository_url
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-region = "ap-northeast-1"
          awslogs-stream-prefix = "example"
          awslogs-group = "app"
        }
      }
    }
  ])
}
