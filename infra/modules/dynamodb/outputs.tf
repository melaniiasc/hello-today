output "table_name" {
  value = aws_dynamodb_table.greeting_history.name
}

output "table" {
  value = aws_dynamodb_table.greeting_history.arn
}