variable "schedule_expression" {
  description = "EventBridge schedule"
  type = string
  default = "cron(0 9 * * ? *)"
}

variable "scheduled_lambda" {
  description = "ARN of the Lambda function to be scheduled"
  type = string

}