variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Application bucket name"
  type        = string
}

variable "environment" {
    description = "Deployment environment"
    type        = string
    default     = "dev"
}

variable "schedule_expression" {
  description = "EventBridge schedule expression"
  type        = string
}