# lambda function that proceses incoming webhooks from github, verifies signature
# and publishes to sns
resource "aws_lambda_function" "publish" {
  function_name = "${var.name}"
  description   = "publish github events to sns"
  handler       = "index.handler"
  memory_size   = "${var.memory_size}"
  role          = "${aws_iam_role.publish.arn}"
  runtime       = "nodejs6.10"
  s3_bucket     = "${var.s3_bucket}"
  s3_key        = "${var.s3_key}"
  timeout       = "${var.timeout}"

  environment {
    variables = {
      CONFIG_PARAMETER_NAMES = "${var.config_parameter_name}"
      DEBUG                  = "${var.debug}"
      NODE_ENV               = "${var.node_env}"
    }
  }
}

# generate a secret to use for signing webhook payloads
resource "random_id" "github_secret" {
  byte_length = 16
}

# define encrypted configuration parameter
resource "aws_ssm_parameter" "configuration" {
  name  = "${var.config_parameter_name}"
  type  = "SecureString"
  value = "${data.template_file.configuration.rendered}"
}

# render configuration as json
data "template_file" "configuration" {
  template = "${file("${path.module}/configuration.json")}"

  vars {
    github_secret = "${random_id.github_secret.hex}"
    log_level     = "${var.log_level}"
    sns_topic_arn = "${aws_sns_topic.github.arn}"
  }
}

# include cloudwatch log group resource definition in order to ensure it is
# removed with function removal
resource "aws_cloudwatch_log_group" "publish" {
  name = "/aws/lambda/${var.name}"
}

# iam role for publish lambda function
resource "aws_iam_role" "publish" {
  name               = "${var.name}"
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
  name   = "${var.name}"
  policy = "${data.aws_iam_policy_document.publish.json}"
}

data "aws_iam_policy_document" "publish" {
  # allow function to publish to github sns topc
  statement {
    actions = [
      "sns:Publish",
    ]

    effect = "Allow"

    resources = [
      "${aws_sns_topic.github.arn}",
    ]
  }

  # allow function to access configuration parameters
  statement {
    actions = [
      "ssm:GetParameter",
    ]

    effect = "Allow"

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${aws_ssm_parameter.configuration.name}",
    ]
  }

  # allow function to manage cloudwatch logs
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
  name       = "${var.name}"
  roles      = ["${aws_iam_role.publish.name}"]
  policy_arn = "${aws_iam_policy.publish.arn}"
}
