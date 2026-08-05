variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "writer_lambda_name" {
  description = "Name of the writer lambda function"
  type        = string
}

variable "sns_topic" {
  description = "ARN of the SNS topic to subscribe to"
  type        = string
}