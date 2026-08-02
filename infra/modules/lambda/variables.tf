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

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "reader_image_uri" {
    description = "URI of the Docker image in ECR for the reader"
    type        = string
}

variable "handler_image_uri" {
    description = "URI of the Docker image in ECR for the handler"
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

variable "image_uri" {
    description = "URI of the Docker image in ECR"
    type        = string
    default = ""
}

variable "handler_ecr_repository" {
    description = "ECR repository for the handler"
    type        = string
}

variable "reader_ecr_repository" {
  description = "ECR repository for the reader"
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
  default = "handler.lambda_handler"
}

variable "reader_handler" {
  description = "Entry point for reader"
    type        = string
    default = "reader.lambda_handler"
}

variable "filename" {
  description = "Path to the deployment package"
  type        = string
  default = "lambda.zip"
}
