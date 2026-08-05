resource "aws_sns_topic" "hello_events" {
  name = "${var.environment}-hello-today-events"
}

resource "aws_sns_topic_subscription" "notifications" {
  topic_arn = aws_sns_topic.hello_events.arn
  protocol  = "sqs"
  endpoint  = var.notifications
}

resource "aws_sns_topic_policy" "hello_events" {
  arn = aws_sns_topic.hello_events.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowWriterPublish"
        Effect = "Allow"
        Principal = {
          AWS = var.writer_role
        }
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.hello_events.arn
      }
    ]
  })
}