// ECR
resource "aws_ecr_repository" "ecr_repository" {
  name = var.ecr_repository_name
}

// Output
output "ecr_repository_url" {
  value = aws_ecr_repository.ecr_repository.repository_url
}
