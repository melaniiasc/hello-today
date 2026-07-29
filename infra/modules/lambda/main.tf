terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
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
        Resource = "${var.s3_bucket}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = var.dynamodb
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      }
    ]
  })
}

resource "aws_lambda_function" "scheduled_lambda" {
  function_name = "scheduled-s3-writer"
  runtime = var.runtime
  handler = var.handler
  filename = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
  role = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
      TABLE_NAME  = var.dynamodb_name
    }
  }
}

resource "aws_lambda_permission" "allow_scheduler" {
  statement_id = "AllowScheduler"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_lambda.function_name
  principal = "scheduler.amazonaws.com"
  source_arn = var.schedule
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_lambda.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = var.http_api
}

resource "aws_lambda_function" "reader" {
  function_name = "greetings-reader"

  runtime = var.runtime
  handler = var.reader_handler

  filename         = "${path.module}/reader.zip"
  source_code_hash = filebase64sha256("${path.module}/reader.zip")

  role = aws_iam_role.reader_role.arn

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_name
    }
  }
}

resource "aws_iam_role" "reader_role" {
  name = "reader-execution-role"
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

resource "aws_iam_role_policy" "reader_policy" {
  role = aws_iam_role.reader_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = var.dynamodb
      },

      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.reader.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda" {

  name = "/aws/lambda/${aws_lambda_function.scheduled_lambda.function_name}"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "reader" {

  name = "/aws/lambda/${aws_lambda_function.reader.function_name}"

  retention_in_days = 7
}