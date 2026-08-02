resource "aws_ecr_repository" "handler" {
  name = "-${var.environment}-lambda-handler-repository"
}

resource "aws_ecr_lifecycle_policy" "handler" {
  policy     = [
    {
      "rulePriority": 1,
      "description": "Keep last 4 images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 4
      },
      "action": {
        "type": "expire"
      }
    }
  ]
  repository = aws_ecr_repository.handler.name
}

resource "aws_ecr_repository" "reader" {
  name = "-${var.environment}-lambda-handler-repository"
}

resource "aws_ecr_lifecycle_policy" "reader" {
  policy     = [
    {
      rulePriority = 1
      description  = "Expire untagged images older than 7 days"
      selection    = {
        tagStatus = "untagged"
        countType = "sinceImagePushed"
        countUnit = "days"
        countNumber = 7
      }
      action       = {
        type = "expire"
      }
    }
  ]
  repository = aws_ecr_repository.reader.name
}
