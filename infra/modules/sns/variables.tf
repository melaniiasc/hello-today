variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "notifications" {
  description = "SQS queue arn for notifications"
  type        = string
}

variable "writer_role" {
  description = "ARN of the IAM role for the writer"
  type        = string
}