output "notifications" {
  value = aws_sqs_queue.notifications.arn
}

output "queue_name" {
  value = aws_sqs_queue.notifications.name
}

output "dlq_name" {
  value = aws_sqs_queue.notifications_dlq.name
}