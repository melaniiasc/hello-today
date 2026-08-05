terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_dynamodb_table" "greeting_history" {
  name         = "${var.environment}-${var.table_name}"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "greeting_date"

  attribute {
    name = "greeting_date"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }
}


