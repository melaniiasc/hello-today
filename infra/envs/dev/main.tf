terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "lambda" {
  source         = "../../modules/lambda"
  environment = var.environment
  schedule       = module.scheduler.schedule
  s3_bucket      = module.s3_bucket.s3_bucket_arn
  http_api       = module.api_gateway.http_api
  function_name  = module.lambda.lambda_name
  dynamodb_name  = module.dynamodb.table_name
  dynamodb       = module.dynamodb.table
  s3_bucket_name = var.bucket_name

}

module "scheduler" {
  source           = "../../modules/scheduler"
  environment = var.environment
  scheduled_lambda = module.lambda.scheduled_lambda
  schedule_expression = var.schedule_expression
}

module "dynamodb" {
  source = "../../modules/dynamodb"
  environment = var.environment
}

module "api_gateway" {
  source               = "../../modules/api"
  api_name             = "my-http-api"
  environment = var.environment
  lambda               = module.lambda.reader_lambda
  lambda_function_name = module.lambda.reader_lambda_name
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket = var.bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}