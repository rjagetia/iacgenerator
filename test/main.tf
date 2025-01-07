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

# Amazon Route 53
resource "aws_route53_zone" "example_com" {
  name = "example.com"
}

# AWS Certificate Manager
resource "aws_acm_certificate" "example_com" {
  domain_name       = "example.com"
  validation_method = "DNS"
}

# Amazon CloudFront
resource "aws_cloudfront_distribution" "example_com" {
  enabled = true
  aliases = ["example.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_api_gateway_rest_api.api_gateway.id

    forwarded_values {
      query_string = true
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  origin {
    domain_name = aws_api_gateway_rest_api.api_gateway.domain_name
    origin_id   = aws_api_gateway_rest_api.api_gateway.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.example_com.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Amazon DynamoDB
resource "aws_dynamodb_table" "example_table" {
  name           = "example-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Additional configuration as needed
}

# Module for Lambda Function
module "lambda" {
  source = "./modules/lambda"

  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  role_arn      = var.role_arn

  # Additional configuration as needed
}
```

This Terraform code defines the necessary resources for the architecture diagram, including Amazon Cognito User Pool, API Gateway, Lambda functions, IAM roles, Route 53, Certificate Manager, CloudFront, and DynamoDB. It also includes a module for creating Lambda functions with configurable parameters.

Note: You will need to provide the necessary values for variables and additional configurations based on your specific requirements. Additionally, you may need to create separate modules or resources for other components not covered in this code, such as Amazon Route 53 domain name mapping or enabling SSL/TLS via custom certificates.