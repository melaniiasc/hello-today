terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.environment}-application"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 8

        properties = {
          title   = "Lambda - Writer"
          region  = var.region
          view    = "timeSeries"
          stacked = false
          period  = 300

          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.writer_lambda_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 24
        height = 8

        properties = {
          title  = "Lambda - Reader"
          region = var.region
          period = 300

          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.reader_lambda_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 16
        width  = 24
        height = 8

        properties = {
          title  = "Lambda - Notifier"
          region = var.region
          period = 300

          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.notifier_lambda_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6

        properties = {
          title  = "Notifications Queue"
          region = var.region
          period = 300

          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              var.queue_name
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 24
        width  = 12
        height = 6

        properties = {
          title  = "Notifications DLQ"
          region = var.region
          period = 300

          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              var.dlq_name
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 24
        height = 8

        properties = {
          title  = "API Gateway"
          region = var.region
          period = 300

          metrics = [
            [
              "AWS/ApiGateway",
              "Count",
              "ApiName",
              var.gateway_name
            ],
            [
              ".",
              "4XXError",
              ".",
              "."
            ],
            [
              ".",
              "5XXError",
              ".",
              "."
            ],
            [
              ".",
              "Latency",
              ".",
              "."
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 38
        width  = 24
        height = 8

        properties = {
          title  = "DynamoDB"
          region = var.region
          period = 300

          metrics = [
            [
              "AWS/DynamoDB",
              "ConsumedReadCapacityUnits",
              "TableName",
              var.dynamodb_table_name
            ],
            [
              ".",
              "ConsumedWriteCapacityUnits",
              ".",
              "."
            ],
            [
              ".",
              "ReadThrottleEvents",
              ".",
              "."
            ],
            [
              ".",
              "WriteThrottleEvents",
              ".",
              "."
            ]
          ]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "writer_error_rate" {
  count = var.environment == "prod" ? 1 : 0

  alarm_name          = "writer-lambda-error-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 3

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  treat_missing_data = "notBreaching"

  metric_query {
    id          = "errors"
    return_data = false

    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"

      dimensions = {
        FunctionName = var.writer_lambda_name
      }

      period = 300
      stat   = "Sum"
    }
  }

  metric_query {
    id          = "invocations"
    return_data = false

    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"

      dimensions = {
        FunctionName = var.writer_lambda_name
      }

      period = 300
      stat   = "Sum"
    }
  }

  metric_query {
    id          = "error_rate"
    expression  = "IF(invocations > 0, errors / invocations * 100, 0)"
    label       = "Writer Lambda Error Rate (%)"
    return_data = true
  }

  alarm_actions = [
    aws_sns_topic.ops_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "notifier_error_rate" {
  count = var.environment == "prod" ? 1 : 0

  alarm_name          = "notifier-lambda-error-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 3

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  treat_missing_data = "notBreaching"

  metric_query {
    id          = "errors"
    return_data = false

    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"

      dimensions = {
        FunctionName = var.notifier_lambda_name
      }

      period = 300
      stat   = "Sum"
    }
  }

  metric_query {
    id          = "invocations"
    return_data = false

    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"

      dimensions = {
        FunctionName = var.notifier_lambda_name
      }

      period = 300
      stat   = "Sum"
    }
  }

  metric_query {
    id          = "error_rate"
    expression  = "IF(invocations > 0, errors / invocations * 100, 0)"
    label       = "Notifier Lambda Error Rate (%)"
    return_data = true
  }

  alarm_actions = [
    aws_sns_topic.ops_alerts.arn
  ]
}


resource "aws_cloudwatch_metric_alarm" "notifications_dlq_depth" {
  alarm_name        = "notifications-dlq-depth"
  alarm_description = "Notifications DLQ contains messages"

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  evaluation_periods  = 1
  datapoints_to_alarm = 1

  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace   = "AWS/SQS"

  dimensions = {
    QueueName = var.dlq_name
  }

  period    = 300
  statistic = "Maximum"

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.ops_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_rate" {
  alarm_name        = "api-5xx-rate"
  alarm_description = "API Gateway 5xx error rate is too high"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 5

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  treat_missing_data = "notBreaching"

  metric_query {
    id          = "errors"
    return_data = false

    metric {
      metric_name = "5XXError"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName = var.gateway_name
      }

      period = 300
      stat   = "Sum"
    }
  }

  metric_query {
    id          = "requests"
    return_data = false

    metric {
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiId = var.gateway_id
      }

      period = 300
      stat   = "Sum"
    }
  }

  metric_query {
    id          = "error_rate"
    expression  = "IF(requests > 0, errors / requests * 100, 0)"
    label       = "API 5xx rate (%)"
    return_data = true
  }

  alarm_actions = [
    aws_sns_topic.ops_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "canary_failure" {
  count = var.environment == "prod" ? 1 : 0

  alarm_name        = "canary-failure"
  alarm_description = "Greetings API synthetic canary is failing"

  namespace   = "CloudWatchSynthetics"
  metric_name = "SuccessPercent"

  dimensions = {
    CanaryName = aws_synthetics_canary.greetings.name
  }

  statistic = "Average"
  period    = 300

  comparison_operator = "LessThanThreshold"
  threshold           = 100

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  treat_missing_data = "breaching"

  alarm_actions = [
    aws_sns_topic.ops_alerts.arn
  ]
}

resource "aws_sns_topic" "ops_alerts" {
  name = "${var.environment}-ops-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_budgets_budget" "this" {
  name         = "budget-monthly"
  budget_type  = "COST"
  limit_amount = "1"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
  time_period_start = "2026-09-01_00:00"
}

resource "aws_s3_bucket" "canary_artifacts" {
  bucket = "${var.environment}-canary-artifacts"

  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id

  rule {
    id     = "expire-canary-artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = 7
    }
  }
}

resource "aws_iam_role" "canary" {
  name = "${var.environment}-canary-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "canary_s3" {
  name = "${var.environment}-canary-s3"
  role = aws_iam_role.canary.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.canary_artifacts.arn,
          "${aws_s3_bucket.canary_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "s3:ListAllMyBuckets",
          "xray:PutTraceSegments"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = "cloudwatch:PutMetricData"

        Resource = "*"

        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CloudWatchSynthetics"
          }
        }
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

data "archive_file" "canary" {
  type        = "zip"
  source_file = "../../../app/canary/canary.py"
  output_path = "../../../app/canary.zip"
}

resource "aws_synthetics_canary" "greetings" {
  name                 = "${var.environment}-greetings-canary"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_artifacts.bucket}/"
  execution_role_arn   = aws_iam_role.canary.arn

  runtime_version = "syn-python-selenium-5.1"

  handler = "canary.handler"

  schedule {
    expression = "rate(8 hours)"
  }

  run_config {
    timeout_in_seconds = 60
  }

  zip_file = data.archive_file.canary.output_path

  success_retention_period = 7
  failure_retention_period = 7

  start_canary = true

  tags = {
    Environment = var.environment
  }
}
