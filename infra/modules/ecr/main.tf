resource "aws_ecr_repository" "handler" {
  name = "writer"
}

resource "aws_ecr_lifecycle_policy" "handler" {
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
  repository = aws_ecr_repository.handler.name
}

resource "aws_ecr_repository" "reader" {
  name = "reader"
}

resource "aws_ecr_lifecycle_policy" "reader" {
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
  repository = aws_ecr_repository.reader.name
}

resource "aws_ecr_repository" "notifier" {
  name = "notifier"
}

resource "aws_ecr_lifecycle_policy" "notifier" {
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
  repository = aws_ecr_repository.notifier.name
}