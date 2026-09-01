variable "region" {
  description = "AWS region"
  type        = string
}
variable "alert_email" {
  description = "Email for alert"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
variable "writer_lambda_name" {
  description = "Name of lambda function"
  type        = string
}
variable "reader_lambda_name" {
  description = "Name of lambda function"
  type        = string
}
variable "notifier_lambda_name" {
  description = "Name of lambda function"
  type        = string
}
variable "queue_name" {
  description = "Name of queue "
  type        = string
}
variable "dlq_name" {
  description = "Name of dead letter queue"
  type        = string
}
variable "gateway_name" {
  description = "Name of API gateway"
  type        = string
}
variable "dynamodb_table_name" {
  description = "Name of Dynamodb table"
  type        = string
}

variable "gateway_id" {
  description = "Id of API Gateway"
  type        = string
}