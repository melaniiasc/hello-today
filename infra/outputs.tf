output "bucket_name" {
  value = aws_s3_bucket.task_1_2.bucket
}

output "lambda_name" {
  value = aws_lambda_function.scheduled_lambda.function_name
}