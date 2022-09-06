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
    path_part = "{fist}"
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

resource "aws_api_gateway_method" "packages_get" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.packages.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_method" "firstGet" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.firstResource.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_method" "secondGet" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.secondResource.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_method" "thirdGet" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.thirdResource.id
    http_method = "GET"
    authorization = "NONE"
}


resource "aws_api_gateway_method_response" "first_method_response" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.firstResource.id
    http_method = aws_api_gateway_method.firstGet.http_method
    status_code = "200"
}

resource "aws_api_gateway_method_response" "second_method_response" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.secondResource.id
    http_method = aws_api_gateway_method.secondGet.http_method
    status_code = "200"
}

resource "aws_api_gateway_method_response" "third_method_response" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.thirdResource.id
    http_method = aws_api_gateway_method.thirdGet.http_method
    status_code = "200"
}

resource "aws_api_gateway_integration" "first_s3_integration" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.firstResource.id
    http_method = aws_api_gateway_method.firstGet.http_method
    integration_http_method = "POST"
    type = "AWS"
    uri = format("arn:aws:apigateway:us-east-2:s3:path/%s/{first}", aws_s3_bucket.sync_bucket.bucket)
    credentials = "arn:aws:iam::074767584099:role/api-gw-s3-read"
  
}

resource "aws_api_gateway_integration" "second_s3_integration" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.secondResource.id
    http_method = aws_api_gateway_method.secondGet.http_method
    integration_http_method = "POST"
    type = "AWS"
    uri = format("arn:aws:apigateway:us-east-2:s3:path/%s/{first}/{second}", aws_s3_bucket.sync_bucket.bucket)
    credentials = "arn:aws:iam::074767584099:role/api-gw-s3-read"
  
}

resource "aws_api_gateway_integration" "third_s3_integration" {
    rest_api_id = aws_api_gateway_rest_api.api_gw.id
    resource_id = aws_api_gateway_resource.thirdResource.id
    http_method = aws_api_gateway_method.thirdGet.http_method
    integration_http_method = "POST"
    type = "AWS"
    uri = format("arn:aws:apigateway:us-east-2:s3:path/%s/{first}/{second}/{third}", aws_s3_bucket.sync_bucket.bucket)
    credentials = "arn:aws:iam::074767584099:role/api-gw-s3-read"
  
}

# resource "aws_api_gateway_integration_response" "s3_first_integration_response" {
    
#     rest_api_id = aws_api_gateway_rest_api.api_gw.id
#     resource_id = aws_api_gateway_resource.firstResource.id
#     status_code = aws_api_gateway_method_response.first_method_response.status_code
#     response_parameters = {"method.response.header.Content-Type" = "True"}
#     response_templates = {"text/html" = "$input.path('$')"}
#     http_method = aws_api_gateway_method_response.first_method_response.http_method
# }



