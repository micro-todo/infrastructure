resource "aws_ecr_repository" "api_gateway" {
  name                 = "microtodo/api-gateway"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  # Nice to have, but expensive for my case
  # image_scanning_configuration {
  #   scan_on_push = true
  # }
  tags = {
    Name = "microtodo_api_gateway_repo"
  }
}

resource "aws_ecr_repository" "users_service" {
  name                 = "microtodo/users-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  # Nice to have, but expensive for my case
  # image_scanning_configuration {
  #   scan_on_push = true
  # }
  tags = {
    Name = "microtodo_users_service_repo"
  }
}

resource "aws_ecr_repository" "tasks_service" {
  name                 = "microtodo/tasks-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  # Nice to have, but expensive for my case
  # image_scanning_configuration {
  #   scan_on_push = true
  # }
  tags = {
    Name = "microtodo_tasks_service_repo"
  }
}

resource "aws_ecr_repository" "notifications_service" {
  name                 = "microtodo/notifications-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  # Nice to have, but expensive for my case
  # image_scanning_configuration {
  #   scan_on_push = true
  # }
  tags = {
    Name = "microtodo_notifications_service_repo"
  }
}

resource "aws_ecr_lifecycle_policy" "api_gateway" {
  repository = aws_ecr_repository.api_gateway.name
  policy     = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countNumber = 7
          countUnit   = "days"
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last 30 tagged images (all tags)"
        selection = {
          tagStatus   = "tagged"
          tagPatternList = ["*"]
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "users_service" {
  repository = aws_ecr_repository.users_service.name
  policy     = aws_ecr_lifecycle_policy.api_gateway.policy
}

resource "aws_ecr_lifecycle_policy" "tasks_service" {
  repository = aws_ecr_repository.tasks_service.name
  policy     = aws_ecr_lifecycle_policy.api_gateway.policy
}

resource "aws_ecr_lifecycle_policy" "notifications_service" {
  repository = aws_ecr_repository.notifications_service.name
  policy     = aws_ecr_lifecycle_policy.api_gateway.policy
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for services"
  value = {
    api_gateway          = aws_ecr_repository.api_gateway.repository_url
    users_service        = aws_ecr_repository.users_service.repository_url
    tasks_service        = aws_ecr_repository.tasks_service.repository_url
    notifications_service= aws_ecr_repository.notifications_service.repository_url
  }
}

data "aws_ecr_authorization_token" "current" {}

output "ecr_registry_url" {
  description = "ECR registry URI"
  value       = split("/", aws_ecr_repository.api_gateway.repository_url)[0]
}

