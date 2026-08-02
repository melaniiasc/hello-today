variable "schedule_expression" {
  description = "EventBridge schedule"
  type = string
}

variable "scheduled_lambda" {
  description = "ARN of the Lambda function to be scheduled"
  type = string

}

variable "environment" {
  description = "Deployment environment"
  type        = string
}