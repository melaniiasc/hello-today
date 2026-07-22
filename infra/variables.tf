variable "region" {
  description = "AWS region"
  type = string
  default = "us-east-1"
}

variable "bucket_name" {
  description = "Application bucket name"
  type = string
}

variable "schedule_expression" {
  description = "EventBridge schedule"
  type = string
  default = "cron(0 9 * * ? *)"
}