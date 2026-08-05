output "lambda_name" {
  value = aws_lambda_function.scheduled_lambda.function_name
}

output "scheduled_lambda" {
  value = aws_lambda_function.scheduled_lambda.arn
}

output "reader_lambda" {
  value = aws_lambda_function.reader.invoke_arn
}
output "reader_lambda_name" {
  value = aws_lambda_function.reader.function_name
}

output "lambda_role" {
  value = aws_iam_role.lambda_role.arn
}