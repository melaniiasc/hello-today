variable "schedule" {
  description = "EventBridge schedule arn"
  type        = string
}

variable "s3_bucket" {
    description = "S3 bucket arn"
    type        = string
}
variable "s3_bucket_name" {
    description = "S3 bucket name"
    type        = string
}

variable "http_api" {
    description = "API arn"
    type        = string
}

variable "dynamodb_name" {
    description = "DynamoDB table name"
    type        = string
}

variable "dynamodb" {
    description = "DynamoDB table arn"
    type        = string
}

variable "function_name" {
  description = "Name of lambda function"
  type        = string
}

variable "runtime" {
  description = "Runtime environment"
  type        = string
  default = "python3.12"
}

variable "handler" {
  description = "Entry point"
  type        = string
  default = "app.handler.lambda_handler"
}

variable "reader_handler" {
  description = "Entry point for reader"
    type        = string
    default = "reader.reader.lambda_handler"
}

variable "filename" {
  description = "Path to the deployment package"
  type        = string
  default = "lambda.zip"
}
