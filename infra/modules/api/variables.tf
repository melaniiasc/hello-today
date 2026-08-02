variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "greetings-api"
}

variable "lambda" {
  description = "Lambda function arn"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}