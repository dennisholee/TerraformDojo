provider "aws" {
  region  = var.region
}

locals {
  appenv       = "${var.app}-${var.env}"
  s3_origin_id = var.app 
}

#===============================================================================
# API Gateway
#===============================================================================

resource "aws_api_gateway_rest_api" "demo" {
  name             = "${local.appenv}-apigateway"
}


#-------------------------------------------------------------------------------
# API Gateway Resource
#-------------------------------------------------------------------------------

resource "aws_api_gateway_resource" "demo" {
  parent_id        = aws_api_gateway_rest_api.demo.root_resource_id
  path_part        = "foopath"
  rest_api_id      = aws_api_gateway_rest_api.demo.id
}

resource "aws_api_gateway_method" "demo" {
  authorization    = "NONE"
  api_key_required = true
  http_method      = "GET"
  resource_id      = aws_api_gateway_resource.demo.id
  rest_api_id      = aws_api_gateway_rest_api.demo.id
}

resource "aws_api_gateway_integration" "demo" {
  http_method      = aws_api_gateway_method.demo.http_method
  resource_id      = aws_api_gateway_resource.demo.id
  rest_api_id      = aws_api_gateway_rest_api.demo.id
  type             = "MOCK"

  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id      = aws_api_gateway_rest_api.demo.id
  resource_id      = aws_api_gateway_resource.demo.id
  http_method      = aws_api_gateway_method.demo.http_method
  status_code      = 200
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id      = aws_api_gateway_rest_api.demo.id
  resource_id      = aws_api_gateway_resource.demo.id
  http_method      = aws_api_gateway_method.demo.http_method
  status_code      = aws_api_gateway_method_response.response_200.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = jsonencode (
      {
        "Result" : "Success"
      }
    )
  }
}

#===============================================================================
# Deployment
#===============================================================================

resource "aws_api_gateway_deployment" "demo" {
  rest_api_id      = aws_api_gateway_rest_api.demo.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.demo.id,
      aws_api_gateway_method.demo.id,
      aws_api_gateway_integration.demo.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "demo" {
  deployment_id    = aws_api_gateway_deployment.demo.id
  rest_api_id      = aws_api_gateway_rest_api.demo.id
  stage_name       = "demo"
}

#===============================================================================
# API Key and Usage plan
#===============================================================================

resource "aws_api_gateway_usage_plan" "demo" {
  name             = "${local.appenv}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.demo.id
    stage  = aws_api_gateway_stage.demo.stage_name
  }
}

resource "aws_api_gateway_api_key" "demo" {
  name             = "${local.appenv}-key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id           = aws_api_gateway_api_key.demo.id
  key_type         = "API_KEY"
  usage_plan_id    = aws_api_gateway_usage_plan.demo.id
}
