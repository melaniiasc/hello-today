terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.environment}-my-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.http_api.id

  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_greetings" {

  api_id = aws_apigatewayv2_api.http_api.id

  route_key          = "GET /greetings"
  authorization_type = "NONE"

  target = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_greeting_by_date" {

  api_id = aws_apigatewayv2_api.http_api.id

  route_key          = "GET /greetings/{date}"
  authorization_type = "NONE"

  target = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}


resource "aws_apigatewayv2_stage" "default" {

  api_id = aws_apigatewayv2_api.http_api.id

  name = "$default"

  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn

    format = jsonencode({
      requestId         = "$context.requestId"
      ip                = "$context.identity.sourceIp"
      requestTime       = "$context.requestTime"
      httpMethod        = "$context.httpMethod"
      routeKey          = "$context.routeKey"
      status            = "$context.status"
      integrationError  = "$context.integrationErrorMessage"
      integrationStatus = "$context.integrationStatus"
    })
  }

  default_route_settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 10
  }
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/api-gateway/${var.environment}-${aws_apigatewayv2_api.http_api.id}"
  retention_in_days = 7
}