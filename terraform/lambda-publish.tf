# lambda function that proceses incoming webhooks from github, verifies signature
# and publishes to sns
resource "aws_lambda_function" "publish" {
  function_name    = "${var.name}"
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
  name = "/aws/lambda/${var.name}"
}

# iam role for publish lambda function
resource "aws_iam_role" "publish" {
  name = "${var.name}"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com", "lambda.amazonaws.com"]
    }
  }
}

# iam policy for lambda function allowing it to publish events to SNS and logs
# to cloudwatch
resource "aws_iam_policy" "publish" {
  name = "${var.name}"

  policy = "${data.aws_iam_policy_document.publish.json}"
}

data "aws_iam_policy_document" "publish" {
  statement {
    actions = [
      "sns:Publish",
    ]

    effect = "Allow"

    resources = [
      "${aws_sns_topic.github.arn}",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    effect    = "Allow"
    resources = ["*"]
  }
}

# attach publish policy to publish role
resource "aws_iam_policy_attachment" "publish" {
  name       = "codebuild-webhook-publish"
  roles      = ["${aws_iam_role.publish.name}"]
  policy_arn = "${aws_iam_policy.publish.arn}"
}
