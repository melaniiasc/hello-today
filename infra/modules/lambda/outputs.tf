output "lambda_name" {
  value=aws_lambda_function.scheduled_lambda.function_name
}

output "scheduled_lambda" {
  value = aws_lambda_function.scheduled_lambda.arn
}

output "reader_lambda" {
  value = aws_lambda_function.reader.arn
}
output "reader_lambda_name" {
  value = aws_lambda_function.reader.function_name
}