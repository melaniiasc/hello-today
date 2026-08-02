variable "table_name" {
  description = "DynamoDB table name"
  type = string
  default = "hello-today-table"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}