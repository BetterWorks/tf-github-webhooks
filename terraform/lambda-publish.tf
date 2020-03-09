data "terraform_remote_state" "chamber" {
  backend = "s3"

  config = {
    bucket = "${var.namespace}-${var.stage}-terraform-state"
    key    = "chamber/terraform.tfstate"
  }
}

locals {
  convert_lambda_file = "placeholder.js"
  chamber_kms_key_arn = data.terraform_remote_state.chamber.outputs.chamber_kms_key_alias_arn
}

data "archive_file" "tf_github_webhooks_file" {
  type        = "zip"
  source_file = "${path.module}/${local.convert_lambda_file}"
  output_path = "${path.module}/${local.convert_lambda_file}.zip"
}

# TODO: make sure that this doesn't overwrite the deployed handler
# lambda function that proceses incoming webhooks from github, verifies signature
# and publishes to sns
resource "aws_lambda_function" "publish" {
  function_name = var.name
  description   = "publish github events to sns"
  handler       = "index.handler"
  memory_size   = var.memory_size
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs12.x"
  filename      = data.archive_file.tf_github_webhooks_file.output_path
  timeout       = var.timeout

  environment {
    variables = {
      CONFIG_PARAMETER_NAMES = aws_ssm_parameter.configuration.name
      DEBUG                 = var.debug
      NODE_ENV              = var.node_env
    }
  }
}

# generate a secret to use for signing webhook payloads
resource "random_id" "github_secret" {
  byte_length = 16
}

# TODO: see if we should be using labels for ssm parameters
module "cicd_tf_github_webhooks_config_label" {
  source     = "git::https://github.com/betterworks/terraform-null-label.git?ref=tags/0.12.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = "cicd"
  attributes = ["proxy", "tf_github_webhooks_config"]
  delimiter  = "/"
  regex_replace_chars = "/[^a-zA-Z0-9-/_]/"
}

# define encrypted configuration parameter
resource "aws_ssm_parameter" "configuration" {
  name      = "/${var.namespace}/${var.stage}/cicd/proxy/tf_github_webhooks_config" # "/${module.cicd_tf_github_webhooks_config_label.id}"
  type      = "SecureString"
  key_id    = local.chamber_kms_key_arn
  value     = data.template_file.configuration.rendered
  overwrite = true
}

# render configuration as json
data "template_file" "configuration" {
  template = file("${path.module}/configuration.json")

  vars = {
    github_secret = random_id.github_secret.hex
    log_level     = var.log_level
    sns_topic_arn = aws_sns_topic.github.arn
  }
}

# include cloudwatch log group resource definition in order to ensure it is
# removed with function removal
resource "aws_cloudwatch_log_group" "publish" {
  name = "/aws/lambda/${var.name}"
}

module "cicd_lambda_role_label" {
  source              = "git::https://github.com/betterworks/terraform-null-label.git?ref=tags/0.12.0"
  namespace           = var.namespace
  stage               = var.stage
  name                = "lambda"
  attributes          = ["role", "tf-github-webhooks"]
}

resource "aws_iam_role" "lambda_role" {
  name               = module.cicd_lambda_role_label.id
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
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

resource "aws_iam_policy" "publish" {
  name   = "${module.cicd_lambda_role_label.id}-publish-policy"
  policy = data.aws_iam_policy_document.publish.json
}

data "aws_iam_policy_document" "publish" {
  statement {
    actions = [
      "sns:Publish",
    ]

    effect = "Allow"

    resources = [
      aws_sns_topic.github.arn,
    ]
  }

  statement {
    actions = [
      "ssm:GetParameter",
    ]

    effect = "Allow"

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${aws_ssm_parameter.configuration.name}",
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

resource "aws_iam_policy_attachment" "publish" {
  name       = "${module.cicd_lambda_role_label.id}-policy-attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.publish.arn
}

