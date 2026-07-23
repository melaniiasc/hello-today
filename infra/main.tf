terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "hello-today-bucket" {
  bucket = var.bucket_name
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.hello-today-bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "scheduled_lambda" {
  function_name = "scheduled-s3-writer"
  runtime = "python3.12"
  handler = "app.handler.lambda_handler"
  filename = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  role = aws_iam_role.lambda_role.arn
}

resource "aws_iam_role" "scheduler_role" {
  name = "scheduler-invoke-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_policy" {
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = aws_lambda_function.scheduled_lambda.arn
    }]
  })
}

resource "aws_scheduler_schedule" "schedule" {
  name = "hello-today-schedule"
  group_name = "default"
  schedule_expression = var.schedule_expression

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn = aws_lambda_function.scheduled_lambda.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}

resource "aws_lambda_permission" "allow_scheduler" {
  statement_id = "AllowScheduler"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_lambda.function_name
  principal = "scheduler.amazonaws.com"
  source_arn = aws_scheduler_schedule.schedule.arn
}
