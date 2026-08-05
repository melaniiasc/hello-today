resource "aws_sqs_queue" "notifications" {
  name                       = "${var.environment}-hello-today-notifications"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 3600
}

resource "aws_sqs_queue" "notifications_dlq" {
  name = "${var.environment}-hello-today-notifications-dlq"
}

resource "aws_sqs_queue_redrive_policy" "notifications" {
  queue_url = aws_sqs_queue.notifications.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "writer_dlq" {
  name = "${var.environment}-hello-writer-dlq"
}

resource "aws_lambda_function_event_invoke_config" "writer" {
  function_name          = var.writer_lambda_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure {
      destination = aws_sqs_queue.writer_dlq.arn
    }
  }
}

resource "aws_sqs_queue_policy" "notifications" {
  queue_url = aws_sqs_queue.notifications.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.notifications.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.sns_topic
          }
        }
      }
    ]
  })
}