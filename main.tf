terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_caller_identity" "current" {}

provider "aws" {
  region  = "us-east-2"
  profile = "walkmlr-Admin"
}

resource "aws_s3_bucket" "sync_bucket" {
    bucket = format("cran-s3-sync-%s",data.aws_caller_identity.current.account_id)
}

resource "aws_api_gateway_rest_api" "api_gw" {
    name = "cran-mirror"
    binary_media_types = [
        "image/jpeg",
        "application/octet",
        "application/pdf"
    ]
    endpoint_configuration {
      types = ["REGIONAL"]
    }
}

resource "aws_api_gateway_resource" "web" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    parent_id = aws_api_gateway_rest_api.api_gw.root_resource_id
    path_part = "web"
}

resource "aws_api_gateway_resource" "packages" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    parent_id = aws_api_gateway_resource.web.id
    path_part = "packages"
}

resource "aws_api_gateway_resource" "firstResource" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    parent_id = aws_api_gateway_resource.packages.id
    path_part = "{first}"
}

resource "aws_api_gateway_resource" "secondResource" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    parent_id = aws_api_gateway_resource.firstResource.id
    path_part = "{second}"
}

resource "aws_api_gateway_resource" "thirdResource" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    parent_id = aws_api_gateway_resource.secondResource.id
    path_part = "{third}"
}

resource "aws_api_gateway_method" "firstGet" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.firstResource.id
    http_method = "GET"
    authorization = "NONE"
    request_parameters = {
        "method.request.path.first" = true
    }
}

resource "aws_api_gateway_method" "secondGet" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.secondResource.id
    http_method = "GET"
    authorization = "NONE"
    request_parameters = {
        "method.request.path.first" = true
        "method.request.path.second" = true
    }
}

resource "aws_api_gateway_method" "thirdGet" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.thirdResource.id
    http_method = "GET"
    authorization = "NONE"
    request_parameters = {
        "method.request.path.first" = true
        "method.request.path.second" = true
        "method.request.path.third" = true
    }
}


resource "aws_api_gateway_method_response" "first_method_response" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.firstResource.id
    http_method = aws_api_gateway_method.firstGet.http_method
    status_code = "200"
    response_parameters = {"method.response.header.Content-Type" = true}
}

resource "aws_api_gateway_method_response" "second_method_response" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.secondResource.id
    http_method = aws_api_gateway_method.secondGet.http_method
    status_code = "200"
    response_parameters = {"method.response.header.Content-Type" = true}
}

resource "aws_api_gateway_method_response" "third_method_response" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.thirdResource.id
    http_method = aws_api_gateway_method.thirdGet.http_method
    status_code = "200"
    response_parameters = {"method.response.header.Content-Type" = true}
}

resource "aws_api_gateway_integration" "first_s3_integration" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.firstResource.id
    http_method = aws_api_gateway_method.firstGet.http_method
    integration_http_method = "GET"
    type = "AWS"
    uri = format("arn:aws:apigateway:us-east-2:s3:path/%s/web/packages/{first}", aws_s3_bucket.sync_bucket.bucket)
    credentials = "arn:aws:iam::074767584099:role/api-gw-s3-read"
    passthrough_behavior = "WHEN_NO_MATCH"
    request_parameters = {
       "integration.request.path.first" = "method.request.path.first"
    }
  
  
}

resource "aws_api_gateway_integration" "second_s3_integration" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.secondResource.id
    http_method = aws_api_gateway_method.secondGet.http_method
    integration_http_method = "GET"
    type = "AWS"

    uri = format("arn:aws:apigateway:us-east-2:s3:path/%s/web/packages/{first}/{second}", aws_s3_bucket.sync_bucket.bucket)
    credentials = "arn:aws:iam::074767584099:role/api-gw-s3-read"
    passthrough_behavior = "WHEN_NO_MATCH"
    request_parameters = {
        "integration.request.path.first" = "method.request.path.first"
        "integration.request.path.second" = "method.request.path.second"
    }
  
}

resource "aws_api_gateway_integration" "third_s3_integration" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.thirdResource.id
    http_method = aws_api_gateway_method.thirdGet.http_method
    integration_http_method = "GET"
    type = "AWS"
    uri = format("arn:aws:apigateway:us-east-2:s3:path/%s/web/packages/{first}/{second}/{third}", aws_s3_bucket.sync_bucket.bucket)
    credentials = "arn:aws:iam::074767584099:role/api-gw-s3-read"
    passthrough_behavior = "WHEN_NO_MATCH"
    request_parameters = {
        "integration.request.path.first" = "method.request.path.first"
        "integration.request.path.second" = "method.request.path.second"
        "integration.request.path.third" = "method.request.path.third"
    }
}

resource "aws_api_gateway_integration_response" "s3_first_integration_response" {
    depends_on = [
      aws_api_gateway_integration.first_s3_integration
    ]
    
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.firstResource.id
    status_code = aws_api_gateway_method_response.first_method_response.status_code
  #
    #response_templates = {"text/html" = "$input.path('$')"}
    response_parameters={"method.response.header.Content-Type" = "integration.response.header.Content-Type"}
    http_method = aws_api_gateway_method_response.first_method_response.http_method
}

resource "aws_api_gateway_integration_response" "s3_second_integration_response" {
     depends_on = [
      aws_api_gateway_integration.second_s3_integration
    ]
    
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.secondResource.id
    status_code = aws_api_gateway_method_response.second_method_response.status_code
    # response_templates = {"text/html" = "$input.path('$')"}
    response_parameters={"method.response.header.Content-Type" = "integration.response.header.Content-Type"}
    http_method = aws_api_gateway_method_response.second_method_response.http_method
}

resource "aws_api_gateway_integration_response" "s3_third_integration_response" {
     depends_on = [
      aws_api_gateway_integration.third_s3_integration
    ]
    
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.thirdResource.id
    status_code = aws_api_gateway_method_response.third_method_response.status_code
  #
   # response_templates = {"text/html" = "$input.path('$')"}
    response_parameters={"method.response.header.Content-Type" = "integration.response.header.Content-Type"}
    http_method = aws_api_gateway_method_response.third_method_response.http_method
}


resource "aws_api_gateway_deployment" "cran-deploy" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.firstResource,
      aws_api_gateway_resource.secondResource,
      aws_api_gateway_resource.thirdResource,
      aws_api_gateway_method.firstGet,
      aws_api_gateway_method.secondGet,
      aws_api_gateway_method.thirdGet,
      aws_api_gateway_integration.first_s3_integration,
      aws_api_gateway_integration.second_s3_integration,
      aws_api_gateway_integration.third_s3_integration,
      aws_api_gateway_integration_response.s3_first_integration_response,
      aws_api_gateway_integration_response.s3_second_integration_response,
      aws_api_gateway_integration_response.s3_third_integration_response
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "cran" {
  deployment_id = aws_api_gateway_deployment.cran-deploy.id
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  stage_name    = "cran"
  
}

