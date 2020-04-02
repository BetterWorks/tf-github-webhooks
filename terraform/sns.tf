module "cicd_tf_github_webhooks_sns_label" {
  source     = "git::https://github.com/betterworks/terraform-null-label.git?ref=tags/0.12.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = "cicd"
  attributes = ["sns", "tf-github-webhooks"]
}

# sns topic for all github webhook events
resource "aws_sns_topic" "github" {
  name = module.cicd_tf_github_webhooks_sns_label.id
}

