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
  default     = "prod"
}

variable "schedule_expression" {
  description = "EventBridge schedule expression"
  type        = string
}

variable "writer_image_uri" {
  description = "URI of the Docker image in ECR for the writer"
  type        = string
}
variable "reader_image_uri" {
  description = "URI of the Docker image in ECR for the reader"
  type        = string
}
variable "notifier_image_uri" {
  description = "URI of the Docker image in ECR for the notifier"
  type        = string
}
