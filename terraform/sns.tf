# sns topic for all github webhook events
resource "aws_sns_topic" "github" {
  name = "codebuild-webhook-github"
}
