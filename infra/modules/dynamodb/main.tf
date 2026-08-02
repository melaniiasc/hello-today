terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_dynamodb_table" "greeting_history" {
  name         = "${var.environment}-${ var.table_name}"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "greeting_date"

  attribute {
    name = "greeting_date"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
}

resource "aws_kms_key" "dynamodb" {

  description = "DynamoDB encryption key"

  enable_key_rotation = true
}

