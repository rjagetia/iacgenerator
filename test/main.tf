```hcl
# AWS Provider
provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

# Amazon Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name = "my-user-pool"
  # Additional configuration as needed
}

# Amazon API Gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "my-api-gateway"
  # Additional configuration as needed
}

# AWS Lambda Functions
module "lambda_ticketa" {
  source = "./modules/lambda"
  function_name = "ticketa"
  handler = "ticketa.handler"
  runtime = "nodejs14.x"
  role_arn = aws_iam_role.lambda_ticketa_role.arn
}

module "lambda_shows" {
  source = "./modules/lambda"
  function_name = "shows"
  handler = "shows.handler"
  runtime = "nodejs14.x"
  role_arn = aws_iam_role.lambda_shows_role.arn
}

module "lambda_info" {
  source = "./modules/lambda"
  function_name = "info"
  handler = "info.handler"
  runtime = "nodejs14.x"
  role_arn = aws_iam_role.lambda_info_role.arn
}

# IAM Roles for Lambda Functions
resource "aws_iam_role" "lambda_ticketa_role" {
  name = "lambda-ticketa-role"
  # Additional configuration as needed
}

resource "aws_iam_role" "lambda_shows_role" {
  name = "lambda-shows-role"
  # Additional configuration as needed
}

resource "aws_iam_role" "lambda_info_role" {
  name = "lambda-info-role"
  # Additional configuration as needed
}

# Amazon DynamoDB Table
resource "aws_dynamodb_table" "dynamodb_table" {
  name = "my-dynamodb-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id"
  # Additional configuration as needed
}

# Amazon CloudFront Distribution
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  origin {
    domain_name = aws_api_gateway_rest_api.api_gateway.domain_name
    origin_id = "api-gateway-origin"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }
  enabled = true
  default_root_object = "index.html"
  # Additional configuration as needed
}

# Amazon Route 53
resource "aws_route53_zone" "hosted_zone" {
  name = "example.com" # Replace with your domain name
}

resource "aws_route53_record" "api_record" {
  zone_id = aws_route53_zone.hosted_zone.id
  name = "api.example.com" # Replace with your desired subdomain
  type = "A"
  alias {
    name = aws_cloudfront_distribution.cloudfront_distribution.domain_name
    zone_id = aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# AWS Certificate Manager
resource "aws_acm_certificate" "ssl_certificate" {
  domain_name = "example.com" # Replace with your domain name
  validation_method = "DNS"
  # Additional configuration as needed
}

# Modules
module "lambda" {
  source = "./modules/lambda"

  function_name = var.function_name
  handler = var.handler
  runtime = var.runtime
  role_arn = var.role_arn
}
```

This Terraform code defines the necessary resources for the architecture diagram, including Amazon Cognito User Pool, API Gateway, Lambda functions, IAM roles, DynamoDB table, CloudFront distribution, Route 53 hosted zone and record, and ACM certificate. The Lambda functions are defined using a module, which can be placed in the `modules/lambda` directory.

Note: You will need to replace the placeholders (e.g., `us-east-1`, `example.com`) with your desired values and provide additional configuration as needed for each resource.