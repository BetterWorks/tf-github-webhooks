output "github_url" {
  value = "${aws_api_gateway_deployment.production.invoke_url}${aws_api_gateway_resource.publish.path}"
}

output "github_secret" {
  value     = random_id.github_secret.hex
  sensitive = true
}

output "sns_topic_arn" {
  value = aws_sns_topic.github.arn
}

