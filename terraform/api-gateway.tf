# base api gateway resource
resource "aws_api_gateway_rest_api" "github" {
  name        = "codebuild-webhook-github"
  description = "API for github webhooks"
}

# route path for publishing github webhook events "/publish"
resource "aws_api_gateway_resource" "publish" {
  rest_api_id = "${aws_api_gateway_rest_api.github.id}"
  parent_id   = "${aws_api_gateway_rest_api.github.root_resource_id}"
  path_part   = "publish"
}

# route method for publishing github webhook events "POST /publish"
resource "aws_api_gateway_method" "publish" {
  rest_api_id   = "${aws_api_gateway_rest_api.github.id}"
  resource_id   = "${aws_api_gateway_resource.publish.id}"
  http_method   = "POST"
  authorization = "NONE"
}

# allow api gateway to invoke publish function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.publish.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.github.id}/*/${aws_api_gateway_method.publish.http_method}${aws_api_gateway_resource.publish.path}"
}

# route reponse for "POST /publish"
resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.github.id}"
  resource_id = "${aws_api_gateway_resource.publish.id}"
  http_method = "${aws_api_gateway_method.publish.http_method}"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# connect route above with our publishing lambda function
resource "aws_api_gateway_integration" "publish" {
  rest_api_id = "${aws_api_gateway_rest_api.github.id}"
  resource_id = "${aws_api_gateway_resource.publish.id}"
  http_method = "${aws_api_gateway_method.publish.http_method}"
  type        = "AWS_PROXY"
  uri         = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.publish.arn}/invocations"

  #  credentials             = "${aws_iam_role.publish.arn}"
  integration_http_method = "POST"
}

# connect response from lambda to route response
resource "aws_api_gateway_integration_response" "publish" {
  rest_api_id = "${aws_api_gateway_rest_api.github.id}"
  resource_id = "${aws_api_gateway_resource.publish.id}"
  http_method = "${aws_api_gateway_method.publish.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  depends_on  = ["aws_api_gateway_integration.publish"]

  response_templates = {
    "application/json" = ""
  }
}

# assign execution url
resource "aws_api_gateway_deployment" "production" {
  depends_on  = ["aws_api_gateway_integration.publish"]
  stage_name  = "production"
  rest_api_id = "${aws_api_gateway_rest_api.github.id}"
}
