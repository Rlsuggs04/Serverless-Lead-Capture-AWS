# Creates the REST API Gateway named EpicReads_api with a regional
# endpoint type meaning it is served from a single AWS region
resource "aws_api_gateway_rest_api" "epicreads_api" {
  name = "EpicReads_api"

  endpoint_configuration {
    types            = ["REGIONAL"]
  }

  tags = {
    Name = "epicreads-api"
  }
}

# Creates a resource (URL path) under the API Gateway root
# This will form the endpoint path that the frontend form will POST to
resource "aws_api_gateway_resource" "epicreads_resource" {
  rest_api_id = aws_api_gateway_rest_api.epicreads_api.id
  parent_id   = aws_api_gateway_rest_api.epicreads_api.root_resource_id
  path_part   = "contact"
}

# Creates the POST method on the epicreads_resource
# No authorization is required since this is a public contact form
resource "aws_api_gateway_method" "epicreads_post" {
  rest_api_id   = aws_api_gateway_rest_api.epicreads_api.id
  resource_id   = aws_api_gateway_resource.epicreads_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integrates the POST method with the Lambda function
# AWS_PROXY passes the full request to Lambda and lets it handle the response
resource "aws_api_gateway_integration" "epicreads_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.epicreads_api.id
  resource_id             = aws_api_gateway_resource.epicreads_resource.id
  http_method             = aws_api_gateway_method.epicreads_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.epicreads_contactus.invoke_arn
}

# Grants API Gateway permission to invoke the Lambda function
# Without this AWS will block API Gateway from triggering Lambda
resource "aws_lambda_permission" "epicreads_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.epicreads_contactus.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.epicreads_api.execution_arn}/*/*"
}

# Enables CORS by creating an OPTIONS method on the resource
# Browsers send an OPTIONS preflight request before the actual POST
# to check if CORS is allowed
resource "aws_api_gateway_method" "epicreads_options" {
  rest_api_id   = aws_api_gateway_rest_api.epicreads_api.id
  resource_id   = aws_api_gateway_resource.epicreads_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Mock integration for the OPTIONS method — API Gateway handles
# the preflight response directly without invoking Lambda
resource "aws_api_gateway_integration" "epicreads_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.epicreads_api.id
  resource_id = aws_api_gateway_resource.epicreads_resource.id
  http_method = aws_api_gateway_method.epicreads_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Defines the 200 response for the OPTIONS method
resource "aws_api_gateway_method_response" "epicreads_options_response" {
  rest_api_id = aws_api_gateway_rest_api.epicreads_api.id
  resource_id = aws_api_gateway_resource.epicreads_resource.id
  http_method = aws_api_gateway_method.epicreads_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Returns the CORS headers in the OPTIONS response so the browser
# knows it is allowed to make the actual POST request
resource "aws_api_gateway_integration_response" "epicreads_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.epicreads_api.id
  resource_id = aws_api_gateway_resource.epicreads_resource.id
  http_method = aws_api_gateway_method.epicreads_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.epicreads_options_integration]
}

# Deploys the API Gateway so it becomes publicly accessible
# Any changes to the API require a new deployment to take effect
resource "aws_api_gateway_deployment" "epicreads_deployment" {
  rest_api_id = aws_api_gateway_rest_api.epicreads_api.id

  depends_on = [
    aws_api_gateway_integration.epicreads_lambda_integration,
    aws_api_gateway_integration_response.epicreads_options_integration_response
  ]
}

# Creates a stage named "prod" which forms part of the API invoke URL
# Stages allow you to have separate environments like dev, staging, prod
resource "aws_api_gateway_stage" "epicreads_stage" {
  rest_api_id   = aws_api_gateway_rest_api.epicreads_api.id
  deployment_id = aws_api_gateway_deployment.epicreads_deployment.id
  stage_name    = "prod"
}

# Outputs the full invoke URL that the frontend will use to POST form data
output "api_invoke_url" {
  value = "${aws_api_gateway_stage.epicreads_stage.invoke_url}/contact"
}