output "handler_ecr_repository" {
  value = aws_ecr_repository.handler.arn
}

output "reader_ecr_repository" {
  value = aws_ecr_repository.reader.arn
}