terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-execution-role"
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
          "sns:Publish"
        ]
        Resource = var.sns_topic
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = var.handler_ecr_repository
      }
    ]
  })
}


resource "aws_lambda_function" "scheduled_lambda" {
  function_name = "${var.environment}-scheduled-s3-writer"
  package_type  = "Image"
  image_uri     = var.handler_image_uri
  role          = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
      TABLE_NAME  = var.dynamodb_name
    }
  }
}

resource "aws_lambda_permission" "allow_scheduler_handler" {
  statement_id  = "AllowScheduler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_lambda.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = var.schedule
}


resource "aws_lambda_permission" "allow_api_gateway_reader" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reader.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.http_api}/*/*"
}

resource "aws_lambda_function" "reader" {
  function_name = "${var.environment}-greetings-reader"
  timeout       = 60
  package_type  = "Image"
  image_uri     = var.reader_image_uri

  role = aws_iam_role.reader_role.arn

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_name
    }
  }
}

resource "aws_iam_role" "reader_role" {
  name = "${var.environment}-reader-execution-role"
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
          "dynamodb:Query",
          "dynamodb:Scan"
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
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = var.reader_ecr_repository
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

resource "aws_cloudwatch_log_group" "notifier" {

  name = "/aws/lambda/${aws_lambda_function.notifier.function_name}"

  retention_in_days = 7
}


resource "aws_lambda_function" "notifier" {
  function_name = "${var.environment}-notifier"
  package_type  = "Image"
  image_uri     = var.notifier_image_uri
  role          = aws_iam_role.notifier_role.arn
}

resource "aws_lambda_event_source_mapping" "notifier" {
  event_source_arn = var.notifications
  function_name    = aws_lambda_function.notifier.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_iam_role_policy" "notifier_policy" {
  role = aws_iam_role.notifier_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem",
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
        Resource = "${aws_cloudwatch_log_group.notifier.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = var.notifier_ecr_repository
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          var.notifications
        ]
      }
    ]
  })
}
resource "aws_iam_role" "notifier_role" {
  name = "${var.environment}-notifier-role"
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