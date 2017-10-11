# lambda function that proceses incoming webhooks from github, verifies signature
# and publishes to sns
resource "aws_lambda_function" "publish" {
  function_name    = "codebuild-webhook-publish"
  description      = "publish github events to sns"
  role             = "${aws_iam_role.publish.arn}"
  handler          = "publish.handler"
  memory_size      = "128"
  timeout          = "10"
  filename         = "${path.module}/../dist/publish.zip"
  source_code_hash = "${data.archive_file.publish.output_base64sha256}"
  runtime          = "nodejs6.10"

  environment {
    variables = {
      SECRET        = "${random_id.github_secret.hex}"
      SNS_TOPIC_ARN = "${aws_sns_topic.github.arn}"
    }
  }
}

# generate artifact for lambda function source code
data "archive_file" "publish" {
  type        = "zip"
  source_file = "${path.module}/../dist/publish.js"
  output_path = "${path.module}/../dist/publish.zip"
}

# generate a secret to use for signing webhook payloads
resource "random_id" "github_secret" {
  byte_length = 16
}

# include cloudwatch log group resource definition in order to ensure it is
# removed with function removal
resource "aws_cloudwatch_log_group" "publish" {
  name = "/aws/lambda/codebuild-webhook-publish"
}

# iam role for publish lambda function
resource "aws_iam_role" "publish" {
  name = "codebuild-webhook-publish"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": ["apigateway.amazonaws.com","lambda.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# iam policy for lambda function allowing it to publish events to SNS and logs
# to cloudwatch
resource "aws_iam_policy" "publish" {
  name = "codebuild-webhook-publish"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "${aws_sns_topic.github.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

# attach publish policy to publish role
resource "aws_iam_policy_attachment" "publish" {
  name       = "codebuild-webhook-publish"
  roles      = ["${aws_iam_role.publish.name}"]
  policy_arn = "${aws_iam_policy.publish.arn}"
}
