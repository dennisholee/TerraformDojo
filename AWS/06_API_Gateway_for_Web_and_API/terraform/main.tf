provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

locals {
  appenv       = "${var.app}-${var.env}"
  s3_origin_id = var.app 
  region       = "us-west-2"
}

resource "random_string" "random" {
  length           = 8
  min_lower        = 8
  special          = true
  override_special = "/@£$"
}

#-------------------------------------------------------------------------------
# S3 Bucket for logs
#-------------------------------------------------------------------------------

resource "aws_s3_bucket" "log-bucket" {
  bucket = "${local.appenv}-${random_string.random.result}-log-bucket"
  acl    = "private"
}

#-------------------------------------------------------------------------------
# S3 Bucket for uploading the src code
#-------------------------------------------------------------------------------

# S3 bucket
resource "aws_s3_bucket" "www-bucket" {
  bucket = "${local.appenv}-${random_string.random.result}-web-bucket"
  acl    = "private"

  website {
    index_document = "index.html"
  }

  tags = {
    Name        = "${local.appenv}-www-bucket"
    Environment = var.env
  }
}

resource "aws_s3_bucket_object" "dist" {
  for_each = fileset("../www", "*")

  bucket = aws_s3_bucket.www-bucket.id
  key    = each.value
  source = "../www/${each.value}"
  etag   = filemd5("../www/${each.value}")
  content_type = "text/html"
  content_encoding = "UTF-8"
}

# ACL

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
}

data "aws_iam_policy_document" "www_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.www-bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.www-bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.www-bucket.id
  policy = data.aws_iam_policy_document.www_s3_policy.json
}

#-------------------------------------------------------------------------------
# API Gateway
#-------------------------------------------------------------------------------

resource "aws_iam_policy" "policy" {
  name        = "test_policy"
  path        = "/" 
  description = "My test policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": "*"
        }
    ]
  })  
}

resource "aws_iam_role" "cloudfront-realtime-log-config-role" {
  name = "CloudFrontRealtimeLogConfigRole-App"

  assume_role_policy = jsonencode({
    Version          = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Environment = var.env
  }
}

resource "aws_iam_role_policy_attachment" "apigw-s3-policy-attachment" {
  role       = aws_iam_role.cloudfront-realtime-log-config-role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_api_gateway_rest_api" "fooapi" {
  name = "${var.app}-api"
}

resource "aws_api_gateway_method" "fooapi-method" {
  rest_api_id   = aws_api_gateway_rest_api.fooapi.id
  resource_id   = aws_api_gateway_rest_api.fooapi.root_resource_id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.fooapi.id
  resource_id             = aws_api_gateway_rest_api.fooapi.root_resource_id
  http_method             = aws_api_gateway_method.fooapi-method.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${local.region}:s3:path//"
  passthrough_behavior    = "WHEN_NO_MATCH"
  credentials             = aws_iam_role.cloudfront-realtime-log-config-role.arn
}

resource "aws_api_gateway_method_response" "response_200" {

  rest_api_id = aws_api_gateway_rest_api.fooapi.id
  resource_id = aws_api_gateway_rest_api.fooapi.root_resource_id
  http_method = aws_api_gateway_method.fooapi-method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = true,
    "method.response.header.Content-Length" = true,
    "method.response.header.Timestamp"      = true
  }
}

resource "aws_api_gateway_integration_response" "integration-response" {
  rest_api_id = aws_api_gateway_rest_api.fooapi.id
  resource_id = aws_api_gateway_rest_api.fooapi.root_resource_id
  http_method = aws_api_gateway_method.fooapi-method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  response_parameters = {
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type",
    "method.response.header.Content-Length" = "integration.response.header.Content-Length",
    "method.response.header.Timestamp"      = "integration.response.header.Date"
  }
}


resource "aws_api_gateway_deployment" "fooapi" {
  stage_name  = "test"
  rest_api_id = aws_api_gateway_rest_api.fooapi.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.fooapi.root_resource_id,
      aws_api_gateway_method.fooapi-method.id,
      aws_api_gateway_integration.integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
