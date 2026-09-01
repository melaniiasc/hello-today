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
  source                  = "../../modules/lambda"
  environment             = var.environment
  schedule                = module.scheduler.schedule
  s3_bucket               = module.s3_bucket.s3_bucket_arn
  http_api                = module.api_gateway.http_api
  function_name           = module.lambda.lambda_name
  dynamodb_name           = module.dynamodb.table_name
  dynamodb                = module.dynamodb.table
  s3_bucket_name          = var.bucket_name
  handler_ecr_repository  = module.ecr.handler_ecr_repository
  reader_ecr_repository   = module.ecr.reader_ecr_repository
  notifier_ecr_repository = module.ecr.notifier_ecr_repository
  handler_image_uri       = var.writer_image_uri
  reader_image_uri        = var.reader_image_uri
  notifier_image_uri      = var.notifier_image_uri
  notifications           = module.sqs.notifications
  sns_topic               = module.sns.sns_topic_arn
}

module "sqs" {
  source             = "../../modules/sqs"
  environment        = var.environment
  writer_lambda_name = module.lambda.lambda_name
  sns_topic          = module.sns.sns_topic_arn
}

module "sns" {
  source        = "../../modules/sns"
  environment   = var.environment
  notifications = module.sqs.notifications
  writer_role   = module.lambda.lambda_role
}

module "scheduler" {
  source              = "../../modules/scheduler"
  environment         = var.environment
  scheduled_lambda    = module.lambda.scheduled_lambda
  schedule_expression = var.schedule_expression
}

module "dynamodb" {
  source      = "../../modules/dynamodb"
  environment = var.environment
}

module "api_gateway" {
  source               = "../../modules/api"
  api_name             = "my-http-api"
  environment          = var.environment
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

module "ecr" {
  source      = "../../modules/ecr"
  environment = var.environment
}

module "observability" {
  source = "../../modules/observability"
  environment = var.environment
  dlq_name = module.sqs.dlq_name
  dynamodb_table_name = module.dynamodb.table_name
  gateway_name = module.api_gateway.http_api
  notifier_lambda_name = module.lambda.reader_lambda_name
  queue_name = module.sqs.queue_name
  reader_lambda_name = module.lambda.reader_lambda_name
  region = var.region
  writer_lambda_name = module.lambda.lambda_name
  gateway_id = module.api_gateway.api_id
}