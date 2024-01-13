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
